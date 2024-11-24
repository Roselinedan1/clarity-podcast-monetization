import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new podcast",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000)
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Can subscribe to a podcast",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000)
            ], wallet1.address),
            
            Tx.contractCall('podcast-monetization', 'subscribe-to-podcast', [
                types.principal(wallet1.address)
            ], wallet2.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
        assertEquals(block.receipts[1].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Can check subscription status",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000)
            ], wallet1.address),
            
            Tx.contractCall('podcast-monetization', 'subscribe-to-podcast', [
                types.principal(wallet1.address)
            ], wallet2.address),
            
            Tx.contractCall('podcast-monetization', 'get-subscription-status', [
                types.principal(wallet1.address),
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[2].result.expectSome(), true);
    },
});
