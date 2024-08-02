# 1. Use BTCPay Server as fiat rates provider

Date: 2024-04-24

## Status

Accepted

## Context

For conversion currencies feature we need access to BTC prices expressed in fiat currencies, and in as many currencies as possible. BTC prices are usually pulled from services like CoinGecko. We do not want every AQUA app to ping CoinGecko for prices, we want to avoid: rate limiting, inconsistent data, and number of other potential issues. The better way is to centralise fiat rates data on our server, and provide the same data to all AQUA users. This way only our server pings CoinGecko and we can easily debug and handle communication issues between server <-> CoinGecko. Custom coding this interaction is time consuming. Alternative is to use BTCPay Server which already knows how to fetch fiat rates and expose rates through a public API.

## Decision

We will use BTCPay Server fiat rates API, as [specified in Greenfield API docs](https://docs.btcpayserver.org/API/Greenfield/v1/#operation/Stores_GetStoreRates). We will reuse an already existing instance, and later if necessary create a new, dedicated instance.
