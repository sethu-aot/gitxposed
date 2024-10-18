#!/bin/bash

# Function to check if a given path is a Git repository
check_git_repo() {
    if [ ! -d "$1/.git" ]; then
        return 1
    else
        return 0
    fi
}

# Function to extract repository owner and name from the Git remote URL
get_github_repo_details() {
    # Get the GitHub remote URL
    git_remote_url=$(git config --get remote.origin.url)

    # Extract owner and repository name using regex
    if [[ $git_remote_url =~ github.com[:/](.*)/(.*)\.git ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]}"
    else
        echo "Could not determine GitHub repository owner and name."
        exit 1
    fi
}

# Prompt for the string to search
echo "Enter the string to search for (e.g., API key, access key, etc.):"
read search_string

# Check if the current directory is a Git repository
while true; do
    if check_git_repo "$(pwd)"; then
        echo "Current directory is a Git repository. Proceeding..."
        break
    else
        # Prompt for a valid Git repository path if it's not a Git repo
        echo "This is not a Git repository."
        echo "Please enter a valid Git repository path:"
        read repo_path
        
        # Change to the new directory if valid
        if [ -d "$repo_path" ]; then
            cd "$repo_path" || exit
        else
            echo "The path entered is not valid. Please try again."
        fi
    fi
done

# Fetch repository owner and name automatically
get_github_repo_details

# Fetch all branches and tags to ensure history is complete
git fetch --all

# Searching for the string in the entire repository history
echo "Searching for the string \"$search_string\" in the entire repository history..."

# Search through the entire repository's commit history and show commit hash, author, filename, line number, and highlighted matching string
git rev-list --all | while read -r commit_hash; do
    git grep -n --color=always -F "$search_string" "$commit_hash" | while read -r match; do
        # Extract the file path and line number from the grep output
        file_path=$(echo "$match" | cut -d':' -f2)
        line_number=$(echo "$match" | cut -d':' -f3)

        # Get the commit author
        commit_author=$(git show -s --format='%an' "$commit_hash")

        # Generate the GitHub link
        github_link="https://github.com/${repo_owner}/${repo_name}/blob/${commit_hash}/${file_path}#L${line_number}"

        # Output the results
        echo "------------------------------------"
        echo "Commit: $commit_hash"
        echo "Author: $commit_author"
        echo "File: $file_path"
        echo "Line: $line_number"
        echo "Match: $match"
        echo ""
        echo "GitHub Link: $github_link"
        echo ""
        echo "To view the commit locally, run:"
        echo "git show $commit_hash"
        echo ""
        echo "To check out the commit locally, run:"
        echo "git checkout $commit_hash"
        echo "------------------------------------"
    done
done

echo "Search completed."
