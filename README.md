# Decentralized Podcast Monetization System

A blockchain-based podcast monetization system built on the Stacks network that allows:

- Podcast creators to register their podcasts
- Set subscription prices
- Receive payments from subscribers
- Manage subscriptions automatically
- Track earnings transparently
- Revenue sharing between collaborators
- Podcast reviews and ratings

## Features

- Podcast registration with title and description
- Configurable subscription prices
- Automated subscription management
- Transparent earnings tracking
- Decentralized payment processing
- Revenue sharing between podcast collaborators
- Platform fee system
- Podcast reviews and ratings system

## How it works

1. Podcast creators register their podcast with details, subscription price, and collaborator shares
2. Listeners can subscribe by paying STX tokens
3. Smart contract manages subscription status and duration
4. Platform fee is collected and remaining earnings are distributed to collaborators
5. Subscribers can leave ratings and reviews
6. All transactions are recorded on the Stacks blockchain

## Technical Implementation

The system uses Clarity smart contracts to handle:
- Podcast registration with collaborator shares
- Subscription management
- Payment processing and revenue distribution
- Access control
- Review and rating system
- Platform fee collection

### Revenue Sharing
Podcast creators can specify multiple collaborators and their revenue shares during registration. When a subscription payment is received:
- Platform fee is deducted (default 5%)
- Remaining amount is distributed according to collaborator shares
- All transactions are automated and transparent

### Reviews System
- Subscribers can leave one review per podcast
- Reviews include 1-5 star rating and written feedback
- Average rating is calculated and stored
- Reviews are permanently stored on-chain
