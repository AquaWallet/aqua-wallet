# Test Plan for Send Flow

## QR Testing

There are two QR flows to test:

1. Asset unknown - This currently is the scanner from the homepage.
- [ ] Since we don't know the asset at this point, the scanner should parse if this is one of the valid managed assets and direct to that send page.
- [ ] Errors: If not one of the valid assets throw an invalid address error.

2. Asset known - This is currently from the Asset Transactions Screen or the Asset-Specific Send Grid
- [ ] Only addresses/invoices/bip21s for that asset should parse and navigate to the send flow
- [ ] Warning: We have a concept of "compatible assets". Lightning and LBTC are compatible, and USDT coins on the Liquid, Eth and Tron networks are compatible.
  This means that if you scan a Lightning address from a LBTC specific screen, the scan should succeed but the state will be on the Lightning Send Flow

### Lighting Specific Scans
- [ ] Currently we scan for invoices, lightning addresses, and LNURL-pay
- [ ] Errors: Expired invoices and invoices without amount currently throw an error on the scan screen

### Bip21
- [ ] We are parsing for bip21s


## Address Input on Send Asset Address Screen

- [ ] If a user pastes an address on in the address input box on the Send Address Screen, the above rules apply. We use the same `addressParserProvider` for both flows.


## Send Flow Navigation

On any address input and parsing:

- [ ] 1. If no address then navigate to Send Address Screen
- [ ] 2. If address but no amount then navigate to Send Amount Screen
- [ ] 3. If both address and amount then navigate to Send Review Screen


## Boltz Integration

- [ ] There is a min and maximum in sats for the boltz swaps, this should appear in the UI
- [ ] Errors: Show error if enter amount below min or above max
- [ ] Warning: There is also an error that boltz will throw if you try to create a second swap with the same invoice. 
    However, we are caching swaps so if we see this user enter the same invoice we catch this and continue the flow. 
- [ ] There is a setup flow that currenlty occurs with a spinner on load of the Send Review Screen. Check code for possible errors


## Sideshift Integration
- [ ] There is a min and maximum for the Sideshift swaps that should appear in the UI
- [ ] There is a setup flow that currenlty occurs with a spinner on load of the Send Review Screen. Check code for possible errors
- [ ] Errors: One particular error in the setup flow is a "not available in your region" error. Setting your VPN to United States will produce this error.


## Fees


## Fiat Input


## Send Max


