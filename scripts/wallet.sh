#!bin/bash

cd packages/cli

WALLET_FILE="wallet.json"

# Example of updating the 'accountPath' field in the JSON file
if [ -f "$WALLET_FILE" ]; then
    # Use jq to extract the accountPath
    current_account_path=$(jq -r '.accountPath' "$WALLET_FILE")

    # Extract the last part of the path (e.g., the number after the last '/')
    last_part=$(echo "$current_account_path" | awk -F '/' '{print $NF}')
    
    # Increment the last part
    new_last_part=$((last_part + 1))
    
    # Construct the new accountPath by replacing the last part
    new_account_path=$(echo "$current_account_path" | sed "s/\/$last_part$/\/$new_last_part/")
    
    # Use jq to update the accountPath field in the wallet.json file
    jq --arg new_account_path "$new_account_path" '.accountPath = $new_account_path' "$WALLET_FILE" > tmp.$$.json && mv tmp.$$.json "$WALLET_FILE"
    
    echo "accountPath updated to $new_account_path in wallet.json"
else
    echo "wallet.json not found!"
    exit 1
fi


while true; do
    # Capture the output of the command
    output=$(sudo yarn cli wallet address)

    # Check if the output contains "Update Status: true"
    if echo "$output" | grep -q "Update Status: true"; then
        echo "Update Status: true, proceeding to the next step."
        break
    else
        echo "Update Status is not true, retrying..."
        sleep 2
    fi
done

