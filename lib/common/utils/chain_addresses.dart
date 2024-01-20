const _externalChainAddresses = {
  'arbitrum': '0x7EF260C6C4330436a843d553b3A6A276663EaFC5',
  'avax': '0xF1d0afeDd2E0cB57D768ea93e8d501df702dcbce',
  'btc': '35AfREkNQqw4hWKCXowEbcSJfPAj2yv43X',
  'bitcoincash': 'bitcoincash:qr56enh78c27hdnke9fzmwcm2gdeh0twtglr564pa0',
  'bsc': '0xfEc424fCb4408c44D48aE7d20dCFE8939C8f95F4',
  'cardano':
      'addr1qxeuusnejkgpxmvxgf5rjngkennpzmxts7apz5u447ydxkkt800u0gu9pp4w0jmy90v4zhxn4umqwjjeqausp9a6tuuqtewgmh',
  'dash': 'Xpc8asfRSVhFBfvytKaKcaWGzobcKnWWUv',
  'doge': 'DHDmqx8JTESNpgEJu79JDbnR97LRoEdGeH',
  'ethereum': '0xB641d3FB02c4E2018018f4478bF39C4231a3E22A',
  'fantom': '0x044fE8D5AeBE3Ec229Bb9f9c34Cf195030aE3b74',
  'lightning':
      '4Bh68jCUZGHbVu45zCVvtcMYesHuduwgajoQcdYRjUQcY6MNa8qd67vTfSNWdtrc33dDECzbPCJeQ8HbiopdeM7EizTTvM8bcShTS7jYVf',
  'litecoin': 'ltc1q5l9helgkj36ehuhh7tva9plfj4ztyxu2e8k3jf',
  'monero':
      '4Bh68jCUZGHbVu45zCVvtcMYesHuduwgajoQcdYRjUQcY6MNa8qd67vTfSNWdtrc33dDECzbPCJeQ8HbiopdeM7Ej9gqbQTFYm74wcSnJk',
  'optimism': '0x08b51b1f615cdC74Af10063c154390c658e0A6A8',
  'polygon': '0x913A229C7Fd6A58dAD9067b262B2A901eF8eA589',
  'ripple': 'rP5vH8tsbuebv62LfJAivqcRcCM2fXMQbQ',
  'smartbch': '0x949732562393a0650162Bcc111A01aB0E326e2fB',
  'solana': 'ABt5H9VbUJdKxjk4LA3GhraGEhbFViAs26etp2ewPxUV',
  'stellar': 'GAL2IMMFZQD2MDT4GOMTPFIB6HQSVNY7PZRWELUMJYJTH7JLLZWG2QBH',
  'zcash': 't1g8KRK7wCbhxv2hzEhXV9sb3EtvJzFyBxn',
};

class ChainAddresses {
  static bool addressExists(String chain) {
    return _externalChainAddresses.containsKey(chain.toLowerCase());
  }

  static String? getAddress(String chain) {
    return _externalChainAddresses[chain.toLowerCase()];
  }
}
