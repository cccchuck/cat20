#!bin/bash

cd packages/cli

get_fee_rate_from_network() {
    local max_retries=3
    local retry_count=0
    local default_fee_rate=2000

    while [ $retry_count -lt $max_retries ]; do
        local response=$(curl -s -f "https://explorer.unisat.io/fractal-mainnet/api/bitcoin-info/fee")
        if [ $? -eq 0 ]; then
            local fee_rate=$(echo "$response" | grep -o '"fastestFee":[0-9]*' | grep -o '[0-9]*')
            if [ -n "$fee_rate" ] && [ $fee_rate -gt 0 ]; then
                echo $fee_rate
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        echo "Get Gas Failed, Retry ($retry_count/$max_retries)" >&2
        sleep 2
    done

    echo "Can't get Gas，use the default Gas: $default_fee_rate" >&2
    echo $default_fee_rate
}

fee_rate=$(get_fee_rate_from_network)
task_count=100
finished_count=0
fetch_gas_every=10

# Parse argu
while [[ $# -gt 0 ]]; do
    case $1 in
        --fee-rate)
            if [ -n "$2" ]; then
                fee_rate=$2
                shift 2
            else
                echo "Error: --fee-rate requires a value"
                exit 1
            fi
            ;;
        --task-count)
            if [ -n "$2" ]; then
                task_count=$2
                shift 2
            else
                echo "Error: --task-count requires a value"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5 --fee-rate $fee_rate"

while [ $finished_count -lt $task_count ]; do
    output=$($command 2>&1 | tee /dev/tty)

    if [[ "$output" == *"too-long-mempool-chain"* ]]; then
        echo "Error：too-long-mempool-chain，skip and continue"
        continue
    elif [[ "$output" == *"mint token [CAT] failed"* ]]; then
        echo "Ignore Error：mint token [CAT] failed"
        continue
    elif [[ "$output" == *"Minting 5.00 CAT"* ]]; then
        finished_count=$((finished_count + 1))
        echo "Process: $finished_count DONE"
        echo ""
    else
        echo "Unknown Error: $output"
        continue
    fi

    if (( finished_count % fetch_gas_every == 0 )); then
        fee_rate=$(get_fee_rate_from_network)
        echo "Fractal Gas Now: $fee_rate"
        command="sudo yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5 --fee-rate $fee_rate"
    fi

    sleep 1
done

echo "Has run $task_count times, exit."

