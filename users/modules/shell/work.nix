{ pkgs
, system
, config
, ...
}:
let
  s = pkgs.writeShellScriptBin "s" ''
    £ -e s101 $1
  '';

  p = pkgs.writeShellScriptBin "p" ''
    £ -e prod $1
  '';

  s101 = pkgs.writeShellScriptBin "s101" ''
    shipper deploy --s101 $1
  '';

  shipthis = pkgs.writeShellScriptBin "shipthis" ''
    branch=$(eval "git rev-parse --symbolic-full-name --abbrev-ref HEAD")
    shipper deploy --s101 $branch
  '';

  shipl = pkgs.writeShellScriptBin "shipl" ''
    shipper deploy local-changes --s101 $1
  '';

  prod = pkgs.writeShellScriptBin "prod" ''
    shipper deploy --prod $1
  '';

  minbuilds = pkgs.writeShellScriptBin "minbuilds" ''
    £ -e prod "config get BASE/app.forceUpgrade"
  '';

  # gets you the id of your production user
  pid = pkgs.writeShellScriptBin "pid" ''
    echo "user_00009D6eX3vpzDDK9FdzSj" | pbcopy
  '';

  # gets you the id of your production user
  deepl = pkgs.writeShellScriptBin "deepl" ''
    function deepl() {
        local thing=$1

        # Construct the regex pattern incorporating the variable
        local pattern="@DeepLinkKey\(.*$thing"
        local directory="$HOME/src/github.com/monzo/android-app"

        # Search with ripgrep, format the output for fzf
        rg --column --line-number --no-heading --color=always "$pattern" "$directory" | \
        fzf --ansi --delimiter ':' \
            --with-nth 3.. \
            --preview 'echo {1} {2} {3}' \
            --preview-window up:3:wrap | \
        awk -F ':' '{print "nvim +" $2 " " $1}' | \
        sh
    }
    deepl $1
  '';

  copypr = pkgs.writeShellScriptBin "copypr" ''
    echo "⏳    Reading pull request $1..."
    content=$(gh pr view --json title,url)
    title=$(echo $content | jq -r .title)
    url=$(echo $content | jq -r .url)
    echo -e ":octocat: $title\n:pr-arrow: $url" | pbcopy
    echo "✅    Pull request copied to clipboard in Slack format."
  '';

  # gets you the id of the most recently created staging user
  sid = pkgs.writeShellScriptBin "sid" ''
    result=$(£ -e s101 'iapi GET /nonprod-user-generator/manual-test-users/list')
    echo $result | jq '[.users[].info_view_items][0][1].code' | sed 's/"//g' | pbcopy
    echo $result | \
    jq '[.users[0]]' | \
        jq 'map({
      created,
      email,
      "Name": (.info_view_items[] | select(.label == "Name").text),
      "User ID": (.info_view_items[] | select(.label == "User ID").code),
      "Supportal": (.info_view_items[] | select(.label == "Link" and .text == "Supportal").href),
      "BizOps": (.info_view_items[] | select(.label == "Link" and .text == "BizOps").href),
      labels
    })'
  '';

  mergeship = pkgs.writeShellScriptBin "mergeship" ''
    function mergeship() {
    local PRNumber
    if [ -n "$1" ]; then
        PRNumber="$1"
    else
        # Fetch the PR number based on the current branch
        echo "🕵️  Getting the PR number for the current branch..."
        PRNumber=$(gh pr view $(git branch --show-current) --json url --template "{{.url}}")
    fi

    gh pr merge -s $PRNumber &&\
    echo "Shipping $PRNumber to production with automated rollback" &&\
    shipper deploy --s101 --disable-progressive-rollouts --skip-confirm-rollout $PRNumber &&\
    shipper deploy --prod --skip-confirm-rollout $PRNumber
    }
    mergeship $1
  '';

  tpr = pkgs.writeShellScriptBin "tpr" ''
    function tpr() {
        # Check if sufficient arguments are provided
        if [ $# -lt 1 ]; then
            echo "Usage: tpr3 [ticket URL or ID] [optional: base branch] [optional: PR title]"
            return 1
        fi

        local ticket_url="$1"  # Capture the full URL for use in PR body
        local ticket_id=$(echo "$1" | awk -F '/' '{print $NF}')

        # Setting base branch
        local base_branch="master"  # Default value
        if [ -n "$2" ]; then
            base_branch="$2"
        fi

        local commit_msg="init"
        local pr_title="$3"
        local use_jira_title="yes"

        # Change to "no" if a PR title is provided
        [ -n "$pr_title" ] && use_jira_title="no"

        # Check if the branch already exists
        if git rev-parse --verify "$ticket_id" >/dev/null 2>&1; then
            echo "Branch $ticket_id already exists."
            return 1
        fi

        # Fetch ticket details from Jira only if needed
        if [ "$use_jira_title" = "yes" ]; then
            # Use environment variables for credentials
            local jira_domain="https://mondough.atlassian.net"
            local jira_user="$JIRA_USER"
            # get your jira api token from here https://id.atlassian.com/manage-profile/security/api-tokens
            local jira_api_token="$JIRA_API_TOKEN"

            local pr_title=$(curl -s -u "$jira_user:$jira_api_token" \
                            -H "Content-Type: application/json" \
                            -X GET \
                            "$jira_domain/rest/api/latest/issue/$ticket_id" | jq -r '.fields.summary')

            if [ -z "$pr_title" ]; then
                echo "Failed to fetch Jira ticket title."
                return 1
            fi
        fi

        # Checkout the base branch and pull the latest changes
        git checkout "$base_branch" && git pull || { echo "Failed to checkout and update $base_branch."; return 1; }

        # Create new branch
        git checkout -b "$ticket_id" || { echo "Failed to create branch $ticket_id."; return 1; }

        # Commit and push
        git commit -m "$commit_msg" --allow-empty && git push || { echo "Failed to commit and push changes."; return 1; }

        # Create a pull request
        gh pr create --title "[$ticket_id] $pr_title" --body "Ticket: [$ticket_id]($ticket_url)" --draft --fill || { echo "Failed to create pull request."; return 1; }
    }

    tpr $1
  '';

  # for maintaining and reading a simple braglist
  brag_old = pkgs.writeShellScriptBin "brag_old" ''
    [ ! -f "$HOME/brag.md" ] && touch "$HOME/brag.md"
    if [[ -z $1 ]]
    then
    cat $HOME/brag.md
    else
    echo "$(date +%d/%m/%Y) | $1" >> $HOME/brag.md
    fi
  '';

  work_pkgs = [
    brag_old
    copypr
    deepl
    mergeship
    minbuilds
    p
    pid
    pkgs.brag
    prod
    s
    s101
    shipl
    shipthis
    sid
    tpr
  ];

  mkOption = pkgs.lib.mkOption;
  types = pkgs.lib.types;

in
{
  options = {
    shell.work.enable = mkOption {
      type = types.bool;
      description = "..."; #TODO:
      default = false;

    };
  };

  config.home.packages = if config.shell.work.enable then work_pkgs else [ ];
}
