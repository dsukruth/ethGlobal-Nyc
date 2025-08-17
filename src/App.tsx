import {
  DynamicContextProvider,
  DynamicWidget,
} from "@dynamic-labs/sdk-react-core";
import { DynamicWagmiConnector } from "@dynamic-labs/wagmi-connector";
import { createConfig, WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { http } from 'viem';
import { mainnet } from 'viem/chains';

// Assuming CalldataViewer.tsx is in the root directory as created earlier
import { CalldataViewer } from '../CalldataViewer';

// Setup wagmi config for wagmi and react-query
const config = createConfig({
  chains: [mainnet],
  multiInjectedProviderDiscovery: false,
  transports: {
    [mainnet.id]: http(),
  },
});

const queryClient = new QueryClient();

// Your main App component
function App() {
  return (
    // Configure Dynamic for wallet connections
    <DynamicContextProvider
      settings={{
        // Find your environmentId at https://app.dynamic.xyz/dashboard/developer
        // IMPORTANT: Please replace this with your actual environment ID
        environmentId: "ee0c9281-4ef8-4bc2-a2ab-97ac5e0be367


",
      }}
    >
      {/* Configure Wagmi for blockchain interaction */}
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <DynamicWagmiConnector>
            <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
              <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h1>Wallet Calldata Explorer</h1>
                <DynamicWidget />
              </header>
              <main>
                {/* Render the CalldataViewer component here */}
                <CalldataViewer />
              </main>
            </div>
          </DynamicWagmiConnector>
        </QueryClientProvider>
      </WagmiProvider>
    </DynamicContextProvider>
  );
}

export default App;

