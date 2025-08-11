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
    shipper deploy local-changes --s101 --no-docker $1
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
    content=$(gh pr view $1 --json title,url)
    title=$(echo $content | jq -r .title)
    url=$(echo $content | jq -r .url)
    echo -e ":octocat: $title\n:pr-arrow: $url" | pbcopy
    echo "✅    Pull request copied to clipboard in Slack format."
  '';

  claudetree = pkgs.writeShellScriptBin "claudetree" ''
    if [ -z "$1" ]; then
      echo "provide a worktree name"
      exit 1
    fi
    git worktree add $1
    cp -r .claude $1
    cd $1
    claude
  '';

  wt = pkgs.writeShellScriptBin "wt" ''
    # Configuration
    WORKTREES_BASE="$HOME/projects/worktrees"
    USERNAME="jackrickards"
    
    # Ensure worktrees directory exists
    mkdir -p "$WORKTREES_BASE"
    
    # Function to get current repo name
    get_repo_name() {
        basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")"
    }
    
    # Function to list existing worktrees for a repo
    list_worktrees() {
        local repo="$1"
        if [ -d "$WORKTREES_BASE/$repo" ]; then
            find "$WORKTREES_BASE/$repo" -maxdepth 1 -type d -name "*" -exec basename {} \; | grep -v "^$repo$" | sort
        fi
    }
    
    # Function to create or access a worktree
    handle_worktree() {
        local repo="$1"
        local branch="$2"
        
        # Check if branch already starts with username
        if [[ "$branch" == "$USERNAME-"* ]]; then
            local worktree_name="$branch"
        else
            local worktree_name="$USERNAME-$branch"
        fi
        
        local worktree_path="$WORKTREES_BASE/$repo/$worktree_name"
        
        # Create worktree if it doesn't exist
        if [ ! -d "$worktree_path" ]; then
            echo "Creating worktree: $worktree_name" >&2
            
            # Create the base directory for this repo's worktrees
            mkdir -p "$WORKTREES_BASE/$repo"
            
            # Create the worktree
            git worktree add "$worktree_path" -b "$branch" >&2 2>/dev/null || git worktree add "$worktree_path" "$branch" >&2
            
            # Copy .claude directory if it exists
            if [ -d ".claude" ]; then
                cp -r .claude "$worktree_path/"
            fi
        fi
        
        echo "$worktree_path"
    }
    
    # Main logic
    if [ $# -eq 0 ]; then
        echo "Usage: wt <branch> [command...]"
        echo "       wt <branch>              # cd to worktree"
        echo "       wt <branch> claude       # run Claude in worktree"
        echo "       wt <branch> git status   # run git status in worktree"
        echo ""
        echo "Current repo: $(get_repo_name)"
        
        current_repo=$(get_repo_name)
        if [ "$current_repo" != "unknown" ]; then
            worktrees=$(list_worktrees "$current_repo")
            if [ -n "$worktrees" ]; then
                echo "Existing worktrees:"
                echo "$worktrees" | sed 's/^/  /'
            fi
        fi
        exit 0
    fi
    
    # Auto-discover current repo
    REPO=$(get_repo_name)
    if [ "$REPO" = "unknown" ]; then
        echo "Error: Not in a git repository"
        exit 1
    fi
    
    BRANCH="$1"
    shift 1
    COMMAND="$@"
    
    if [ -z "$BRANCH" ]; then
        echo "Error: Branch name required"
        exit 1
    fi
    
    # Handle the worktree (create if needed)
    WORKTREE_PATH=$(handle_worktree "$REPO" "$BRANCH")
    
    if [ -n "$COMMAND" ]; then
        echo "Running: $COMMAND"
        echo "In: $WORKTREE_PATH"
        cd "$WORKTREE_PATH" && eval "$COMMAND"
    else
        echo "Worktree ready: $WORKTREE_PATH"
        echo "Run: cd \"$WORKTREE_PATH\""
    fi
  '';

  tdiff = pkgs.writeShellScriptBin "tdiff" ''
    # Parse command line arguments
    TEST_WHOLE_SERVICE=false
    if [ "$1" = "--full" ] || [ "$1" = "-f" ]; then
        TEST_WHOLE_SERVICE=true
    fi

    # Get the base branch (usually master)
    BASE_BRANCH="master"

    # Get list of changed Go files compared to base branch, excluding generated proto files
    CHANGED_FILES=$(git diff --name-only $BASE_BRANCH...HEAD | grep '\.go$' | grep -v '/proto/')

    if [ -z "$CHANGED_FILES" ]; then
        echo "No Go file changes detected"
        exit 0
    fi

    if [ "$TEST_WHOLE_SERVICE" = true ]; then
        # Extract unique service names from changed Go files
        SERVICES=$(echo "$CHANGED_FILES" | grep -E '^service\.[^/]+/' | cut -d'/' -f1 | sort -u)

        if [ -z "$SERVICES" ]; then
            echo "No service changes detected"
            exit 0
        fi

        # Run tests for each affected service
        for SERVICE in $SERVICES; do
            echo "Running tests for $SERVICE..."
            gotestsum ./$SERVICE/...
            if [ $? -ne 0 ]; then
                echo "Tests failed for $SERVICE"
                exit 1
            fi
        done
    else
        # Extract unique service/package combinations from changed Go files
        PACKAGES=$(echo "$CHANGED_FILES" | grep -E '^service\.[^/]+/[^/]+/' | sed 's|/[^/]*$||' | sort -u)

        if [ -z "$PACKAGES" ]; then
            echo "No Go package changes detected"
            exit 0
        fi

        # Run tests for each affected package
        for PACKAGE in $PACKAGES; do
            echo "Running tests for $PACKAGE..."
            gotestsum ./$PACKAGE/...
            if [ $? -ne 0 ]; then
                echo "Tests failed for $PACKAGE"
                exit 1
            fi
        done
    fi

    echo "All tests passed!"
  '';

  linear = pkgs.writeShellScriptBin "linear" ''
    if [ $# -lt 3 ]; then
        echo "Usage: linear <project> <name> <description> [labels...]"
        echo "Available labels: Backend, Android, iOS"
        exit 1
    fi

    PROJECT_NAME="$1"
    NAME="$2"  
    DESCRIPTION="$3"
    shift 3
    LABELS="$@"

    # Clean up newlines and carriage returns but don't escape quotes yet (jq will handle that)
    NAME=$(echo "$NAME" | tr '\n\r' '  ')
    DESCRIPTION=$(echo "$DESCRIPTION" | tr '\n\r' '  ')

    # Read API key from local file
    API_KEY_FILE="$HOME/.linear_api_key"
    if [ ! -f "$API_KEY_FILE" ]; then
        echo "Error: Linear API key file not found at $API_KEY_FILE"
        echo "Please create this file with your Linear API key"
        exit 1
    fi

    API_KEY=$(cat "$API_KEY_FILE")
    if [ -z "$API_KEY" ]; then
        echo "Error: API key is empty"
        exit 1
    fi

    # Fixed team ID for Wealth: Savings
    TEAM_ID="7d772272-0780-4db4-9452-2ca325752e2f"

    # Query for projects to find the matching project ID
    PROJECTS_QUERY='{"query": "query { team(id: \"'$TEAM_ID'\") { projects { nodes { id name } } } }"}'
    
    PROJECTS_RESPONSE=$(curl -s -X POST \
      -H "Authorization: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$PROJECTS_QUERY" \
      https://api.linear.app/graphql)

    # Find project ID by name (case insensitive)
    PROJECT_ID=$(echo "$PROJECTS_RESPONSE" | jq -r --arg name "$PROJECT_NAME" '.data.team.projects.nodes[] | select(.name | test($name; "i")) | .id')

    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
        echo "❌ Project not found: $PROJECT_NAME"
        echo "Available projects:"
        echo "$PROJECTS_RESPONSE" | jq -r '.data.team.projects.nodes[] | "  - " + .name'
        exit 1
    fi

    # Handle labels if provided
    LABEL_IDS=""
    if [ -n "$LABELS" ]; then
        # Query for team labels to get IDs
        LABELS_QUERY='{"query": "query { team(id: \"'$TEAM_ID'\") { labels { nodes { id name } } } }"}'
        
        LABELS_RESPONSE=$(curl -s -X POST \
          -H "Authorization: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$LABELS_QUERY" \
          https://api.linear.app/graphql)

        # Build label IDs array
        LABEL_ID_ARRAY="["
        FIRST_LABEL=true
        for LABEL in $LABELS; do
            LABEL_ID=$(echo "$LABELS_RESPONSE" | jq -r --arg name "$LABEL" '.data.team.labels.nodes[] | select(.name | test($name; "i")) | .id')
            if [ -n "$LABEL_ID" ] && [ "$LABEL_ID" != "null" ]; then
                if [ "$FIRST_LABEL" = true ]; then
                    LABEL_ID_ARRAY="$LABEL_ID_ARRAY\"$LABEL_ID\""
                    FIRST_LABEL=false
                else
                    LABEL_ID_ARRAY="$LABEL_ID_ARRAY, \"$LABEL_ID\""
                fi
            else
                echo "⚠️  Label not found: $LABEL"
            fi
        done
        LABEL_ID_ARRAY="$LABEL_ID_ARRAY]"
        
        if [ "$LABEL_ID_ARRAY" != "[]" ]; then
            LABEL_IDS=", labelIds: $LABEL_ID_ARRAY"
        fi
    fi

    echo "📝 Creating issue in project: $PROJECT_NAME (ID: $PROJECT_ID)"

    # Properly escape strings for GraphQL
    ESCAPED_TITLE=$(echo "$NAME" | jq -Rs .)
    ESCAPED_DESCRIPTION=$(echo "$DESCRIPTION" | jq -Rs .)

    # Build GraphQL mutation string
    if [ -n "$LABEL_IDS" ]; then
        GRAPHQL_QUERY="mutation { issueCreate(input: { title: $ESCAPED_TITLE, description: $ESCAPED_DESCRIPTION, teamId: \"$TEAM_ID\", projectId: \"$PROJECT_ID\", labelIds: $LABEL_ID_ARRAY }) { success issue { id title url } } }"
    else
        GRAPHQL_QUERY="mutation { issueCreate(input: { title: $ESCAPED_TITLE, description: $ESCAPED_DESCRIPTION, teamId: \"$TEAM_ID\", projectId: \"$PROJECT_ID\" }) { success issue { id title url } } }"
    fi

    # Create the JSON request
    MUTATION=$(jq -n --arg query "$GRAPHQL_QUERY" '{query: $query}')

    # Make the API request
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$MUTATION" \
        https://api.linear.app/graphql)

    # Parse response
    SUCCESS=$(echo "$RESPONSE" | jq -r '.data.issueCreate.success')
    
    if [ "$SUCCESS" = "true" ]; then
        ISSUE_ID=$(echo "$RESPONSE" | jq -r '.data.issueCreate.issue.id')
        ISSUE_URL=$(echo "$RESPONSE" | jq -r '.data.issueCreate.issue.url')
        echo "✅ Issue created successfully!"
        echo "ID: $ISSUE_ID"
        echo "URL: $ISSUE_URL"
    else
        echo "❌ Failed to create issue"
        echo "Response: $RESPONSE"
        exit 1
    fi
  '';

  linear-projects = pkgs.writeShellScriptBin "linear-projects" ''
    # Read API key from local file
    API_KEY_FILE="$HOME/.linear_api_key"
    if [ ! -f "$API_KEY_FILE" ]; then
        echo "Error: Linear API key file not found at $API_KEY_FILE"
        exit 1
    fi

    API_KEY=$(cat "$API_KEY_FILE")
    
    echo "Fetching Linear projects for Wealth: Savings team..."
    
    QUERY='{"query": "query { team(id: \"7d772272-0780-4db4-9452-2ca325752e2f\") { projects { nodes { id name } } } }"}'
    
    RESPONSE=$(curl -s -X POST \
      -H "Authorization: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$QUERY" \
      https://api.linear.app/graphql)
    
    echo "Projects:"
    echo "$RESPONSE" | jq -r '.data.team.projects.nodes[] | "ID: " + .id + " | Name: " + .name'
  '';

  linear-get = pkgs.writeShellScriptBin "linear-get" ''
    if [ $# -ne 1 ]; then
        echo "Usage: linear-get <ticket_url_or_branch>"
        exit 1
    fi

    INPUT="$1"

    # Check if input is a URL or branch name
    if [[ "$INPUT" =~ ^https?:// ]]; then
        # Extract issue ID from URL - Linear URLs are like https://linear.app/monzo/issue/WS-123/title
        ISSUE_ID=$(echo "$INPUT" | sed -n 's|.*/issue/\([^/]*\)/.*|\1|p')
        
        if [ -z "$ISSUE_ID" ]; then
            echo "Error: Could not extract issue ID from URL: $INPUT"
            echo "Expected format: https://linear.app/workspace/issue/ISSUE-ID/..."
            exit 1
        fi
    else
        # Assume it's a branch name - extract issue ID from branch like sav-123-feature-name or jackrickards-sav-123-feature-name
        # Use grep to find the pattern anywhere in the string
        ISSUE_ID=$(echo "$INPUT" | grep -o '[a-zA-Z]\+-[0-9]\+' | head -1 | tr '[:lower:]' '[:upper:]')
        
        if [ -z "$ISSUE_ID" ]; then
            echo "Error: Could not extract issue ID from branch: $INPUT"
            echo "Expected format: [username-]prefix-number-description (e.g., sav-123-feature-name or jackrickards-sav-123-feature-name)"
            exit 1
        fi
    fi

    # Read API key from local file
    API_KEY_FILE="$HOME/.linear_api_key"
    if [ ! -f "$API_KEY_FILE" ]; then
        echo "Error: Linear API key file not found at $API_KEY_FILE"
        exit 1
    fi

    API_KEY=$(cat "$API_KEY_FILE")

    # Query for issue details - properly escape the issue ID as a string
    QUERY=$(jq -n --arg issueId "$ISSUE_ID" '{query: ("query { issue(id: \"" + $issueId + "\") { id title description branchName } }")}')

    RESPONSE=$(curl -s -X POST \
      -H "Authorization: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$QUERY" \
      https://api.linear.app/graphql)

    # Check if issue was found
    if echo "$RESPONSE" | jq -e '.data.issue' > /dev/null 2>&1; then
        # Extract and format the data as JSON
        echo "$RESPONSE" | jq '{
          title: .data.issue.title,
          body: .data.issue.description,
          "branch-name": .data.issue.branchName
        }'
    else
        echo "Error: Issue not found or API error"
        echo "Response: $RESPONSE"
        exit 1
    fi
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
    claudetree
    copypr
    deepl
    linear
    linear-get
    linear-projects
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
    tdiff
    tpr
    wt
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
