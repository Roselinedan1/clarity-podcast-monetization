import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a podcast with collaborators",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000),
                types.list([
                    types.tuple({
                        address: types.principal(wallet1.address),
                        share: types.uint(60)
                    }),
                    types.tuple({
                        address: types.principal(wallet2.address),
                        share: types.uint(40)
                    })
                ])
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Can subscribe and distribute earnings to collaborators",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const wallet3 = accounts.get('wallet_3')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000),
                types.list([
                    types.tuple({
                        address: types.principal(wallet1.address),
                        share: types.uint(60)
                    }),
                    types.tuple({
                        address: types.principal(wallet2.address),
                        share: types.uint(40)
                    })
                ])
            ], wallet1.address),
            
            Tx.contractCall('podcast-monetization', 'subscribe-to-podcast', [
                types.principal(wallet1.address)
            ], wallet3.address)
        ]);
        
        assertEquals(block.receipts[1].result.expectOk(), true);
    },
});

Clarinet.test({
    name: "Can review a podcast",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('podcast-monetization', 'register-podcast', [
                types.ascii("My Podcast"),
                types.ascii("A great podcast about tech"),
                types.uint(1000000),
                types.list([
                    types.tuple({
                        address: types.principal(wallet1.address),
                        share: types.uint(100)
                    })
                ])
            ], wallet1.address),
            
            Tx.contractCall('podcast-monetization', 'review-podcast', [
                types.principal(wallet1.address),
                types.uint(5),
                types.ascii("Great podcast!")
            ], wallet2.address)
        ]);
        
        assertEquals(block.receipts[1].result.expectOk(), true);
    },
});
