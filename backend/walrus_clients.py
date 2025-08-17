import os
import requests
from dotenv import load_dotenv
from viem import create_client, http

# Load environment variables from the root .env file
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '../.env'))

# Get configuration from environment variables
ZIRCUIT_RPC_URL = os.getenv("ZIRCUIT_RPC")
WALRUS_BASE_URL = os.getenv("WALRUS_BASE")

def pull_and_store_calldata(wallet_address: str):
    """
    Pulls transaction calldata for a specific wallet from the latest block
    on the Zircuit testnet and stores it in Walrus.

    Args:
        wallet_address (str): The checksummed address of the wallet to monitor.
    """
    if not ZIRCUIT_RPC_URL or not WALRUS_BASE_URL:
        print("🛑 Error: ZIRCUIT_RPC and WALRUS_BASE must be set in the .env file.")
        return

    print(f"🔗 Connecting to Zircuit testnet at {ZIRCUIT_RPC_URL}...")
    client = create_client(http(ZIRCUIT_RPC_URL))

    try:
        print("📦 Fetching the latest block...")
        block = client.get_block(
            block_tag='latest',
            include_transactions=True
        )
        print(f"✅ Fetched block number: {block['number']}")

        calldata_to_store = []
        print(f"🔍 Searching for transactions to '{wallet_address}'...")

        for tx in block.get('transactions', []):
            if tx.get('to') and tx['to'].lower() == wallet_address.lower():
                calldata = tx.get('input')
                if calldata and calldata != '0x':
                    print(f"  - Found transaction {tx['hash'][:10]}... with calldata.")
                    calldata_to_store.append({
                        "tx_hash": tx['hash'],
                        "calldata": calldata
                    })

        if not calldata_to_store:
            print("😴 No transactions with calldata found for this address in the latest block.")
            return

        print(f"\n💾 Storing {len(calldata_to_store)} piece(s) of calldata in Walrus at {WALRUS_BASE_URL}...")
        
        for item in calldata_to_store:
            # In a real scenario, you might structure the data differently,
            # but for this example, we'll store the calldata directly.
            payload = {
                "description": f"Calldata from tx {item['tx_hash']}",
                "arbitrary_data": {
                    "calldata": item['calldata']
                }
            }
            response = requests.post(WALRUS_BASE_URL, json=payload)
            
            if response.status_code == 201:
                print(f"  - Successfully stored calldata from tx {item['tx_hash'][:10]}...")
            else:
                print(f"  - ⚠️ Failed to store calldata. Status code: {response.status_code}, Response: {response.text}")

        print("\n🎉 Process complete.")

    except Exception as e:
        print(f"❌ An error occurred: {e}")

if __name__ == '__main__':
    # --- Example Usage ---
    # Replace with the actual wallet address you want to track.
    # Ensure your .env file is correctly set up at the project root.
    user_wallet_address = os.getenv("SMART_ACCOUNT_ADDR", "0xYourWalletAddressHere")
    
    if user_wallet_address == "0xYourWalletAddressHere":
        print("👉 Please set the SMART_ACCOUNT_ADDR in your .env file or replace the placeholder.")
    else:
        pull_and_store_calldata(user_wallet_address)
