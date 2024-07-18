#!/bin/bash

# Define variables
OWNER="gurgenyegor"
REPO="test-merge"
WORKFLOW_NAME="temp.yml"
BRANCH="main"
ENVIRONMENT=live
PROJECT_ID=uc-next

# Trigger the workflow
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_NAME/dispatches \
   -f "ref=main" -f "inputs[project_id]=$PROJECT_ID" -f "inputs[environment]=$ENVIRONMENT" >> /dev/null

sleep 10
# Get the workflow run ID
workflow_run_id=$(gh run list --json databaseId -R $OWNER/$REPO --branch $BRANCH --workflow $WORKFLOW_NAME --limit 1 | jq -r '.[0].databaseId')
if [ -z "$workflow_run_id" ]; then
  echo "Failed to get the workflow run ID."
  exit 1
fi
echo $workflow_run_id
# Check the workflow status in a loop
while true; do
  status=$(gh run view $workflow_run_id -R $OWNER/$REPO --json status --jq .status)

  if [ "$status" == "completed" ]; then
    conclusion=$(gh run view $workflow_run_id -R $OWNER/$REPO --json conclusion --jq .conclusion)

    if [ "$conclusion" == "success" ]; then
      echo "Workflow completed successfully!"
      exit 0
    else
      echo "Workflow failed with conclusion: $conclusion"
      exit 1
    fi
  fi

  echo "Workflow is still in progress..."
  sleep 10
done
