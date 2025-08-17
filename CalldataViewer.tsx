import { useState } from 'react';
import { useAccount } from 'wagmi';

// Define the structure of a transaction object from the Etherscan API
interface Transaction {
  hash: string;
  to: string;
  input: string; // This is the calldata
}

export function CalldataViewer() {
  const { address, isConnected } = useAccount();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * Fetches the transaction history for the connected wallet address
   * from the Etherscan API and filters for transactions with calldata.
   */
  const fetchTransactions = async () => {
    if (!address) {
      setError("Wallet is not connected.");
      return;
    }

    setIsLoading(true);
    setError(null);
    setTransactions([]);

    // IMPORTANT: Replace with your actual Etherscan API key
    const ETHERSCAN_API_KEY = process.env.NEXT_PUBLIC_ETHERSCAN_API_KEY || 'PE6R9VY5XPKEDQ91H3TU6TZPXXBJZ5M6IJ';
    
    // Using the Etherscan API endpoint for Ethereum Mainnet.
    // Change the domain for other networks (e.g., api-sepolia.etherscan.io for Sepolia).
    const apiUrl = `https://api.etherscan.io/api?module=account&action=txlist&address=${address}&startblock=0&endblock=99999999&sort=desc&apikey=${ETHERSCAN_API_KEY}`;

    try {
      const response = await fetch(apiUrl);
      const data = await response.json();

      if (data.status === "1" && Array.isArray(data.result)) {
        // Filter for transactions that have calldata (input is not '0x')
        const txsWithCalldata = data.result.filter(
          (tx: Transaction) => tx.input && tx.input.toLowerCase() !== '0x'
        );
        setTransactions(txsWithCalldata);
      } else {
        // Handle API errors (e.g., rate limits)
        setError(data.message || "Could not fetch transactions.");
      }
    } catch (err) {
      console.error("Failed to fetch transaction data:", err);
      setError("An unexpected error occurred. See console for details.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ fontFamily: 'sans-serif', padding: '1rem' }}>
      <h2>Transaction Calldata Viewer</h2>
      {!isConnected ? (
        <p>Please connect your wallet to view transaction data.</p>
      ) : (
        <div>
          <p>
            <strong>Connected Wallet:</strong> {address}
          </p>
          <button onClick={fetchTransactions} disabled={isLoading}>
            {isLoading ? 'Fetching Calldata...' : 'Fetch Transaction Calldata'}
          </button>

          {error && <p style={{ color: 'red', marginTop: '1rem' }}>Error: {error}</p>}

          {transactions.length > 0 && (
            <div style={{ marginTop: '1.5rem' }}>
              <h3>Transactions with Calldata:</h3>
              <ul style={{ listStyle: 'none', padding: 0 }}>
                {transactions.map((tx) => (
                  <li key={tx.hash} style={{ border: '1px solid #ccc', borderRadius: '8px', padding: '1rem', marginBottom: '1rem' }}>
                    <p><strong>Tx Hash:</strong> <a href={`https://etherscan.io/tx/${tx.hash}`} target="_blank" rel="noopener noreferrer">{tx.hash}</a></p>
                    <p><strong>To:</strong> {tx.to}</p>
                    <strong>Calldata:</strong>
                    <pre 
                      style={{ 
                        background: '#f4f4f4', 
                        padding: '0.5rem', 
                        borderRadius: '4px', 
                        wordWrap: 'break-word', 
                        whiteSpace: 'pre-wrap',
                        maxHeight: '150px',
                        overflowY: 'auto'
                      }}
                    >
                      {tx.input}
                    </pre>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
