import type {
  User, Product, Order, Transaction, Channel, Message, Vote, Proposal,
  CompAward, Scan, TreasuryWallet, TransparencyOverview, ActivityFeedItem,
  MonthlyEarning,
} from './types'

export const currentUser: User = {
  id: 'usr_001',
  email: 'jake.mitchell@email.com',
  username: 'jakemitch',
  firstName: 'Jake',
  lastName: 'Mitchell',
  phone: '+1 (555) 234-5678',
  address: {
    street: '742 Evergreen Terrace',
    city: 'Austin',
    state: 'TX',
    zip: '78701',
    country: 'US',
  },
  tier: 'vip',
  permanentTier: 'vip',
  effectiveTier: 'vip',
  totalScans: 347,
  quarterlyScans: 42,
  lifetimeUSDT: 186.50,
  walletAddress: '0x7a3B...9f4E',
  memberSince: '2024-06-15',
}

const flavors = ['Spearmint', 'Wintergreen', 'Bubblegum', 'Blue Razz', 'Mint Ice', 'Citrus', 'Cinnamon', 'Coffee']
const strengths = ['3mg', '6mg', '9mg']

export const products: Product[] = flavors.flatMap((flavor, fi) =>
  strengths.map((strength, si) => ({
    id: `prod_${String(fi * 3 + si + 1).padStart(3, '0')}`,
    name: `BlakJaks ${flavor} ${strength}`,
    flavor,
    strength,
    price: 4.99,
    description: `Premium ${flavor.toLowerCase()} nicotine pouches at ${strength} strength. Smooth, satisfying, and blockchain-verified.`,
    image: `/products/${flavor.toLowerCase().replace(' ', '-')}-${strength}.webp`,
    inStock: !(flavor === 'Coffee' && strength === '9mg'),
  }))
)

export const orders: Order[] = [
  {
    id: 'ord_001', orderNumber: 'BJ-20250187', date: '2025-02-10T14:23:00Z',
    items: [{ product: products[0], quantity: 3, unitPrice: 4.99, subtotal: 14.97 }, { product: products[4], quantity: 2, unitPrice: 4.99, subtotal: 9.98 }],
    subtotal: 24.95, shipping: 4.99, tax: 2.00, total: 31.94, status: 'delivered', trackingNumber: '1Z999AA10123456784', ageVerificationId: 'AV-9823',
  },
  {
    id: 'ord_002', orderNumber: 'BJ-20250201', date: '2025-02-14T09:15:00Z',
    items: [{ product: products[6], quantity: 5, unitPrice: 4.99, subtotal: 24.95 }],
    subtotal: 24.95, shipping: 0, tax: 2.00, total: 26.95, status: 'shipped', trackingNumber: '1Z999AA10123456785',
  },
  {
    id: 'ord_003', orderNumber: 'BJ-20250215', date: '2025-02-16T16:42:00Z',
    items: [{ product: products[1], quantity: 2, unitPrice: 4.99, subtotal: 9.98 }, { product: products[10], quantity: 1, unitPrice: 4.99, subtotal: 4.99 }],
    subtotal: 14.97, shipping: 4.99, tax: 1.20, total: 21.16, status: 'processing',
  },
  {
    id: 'ord_004', orderNumber: 'BJ-20250102', date: '2025-01-02T11:30:00Z',
    items: [{ product: products[3], quantity: 10, unitPrice: 4.99, subtotal: 49.90 }],
    subtotal: 49.90, shipping: 0, tax: 3.99, total: 53.89, status: 'delivered', trackingNumber: '1Z999AA10123456780',
  },
  {
    id: 'ord_005', orderNumber: 'BJ-20250118', date: '2025-01-18T08:00:00Z',
    items: [{ product: products[7], quantity: 1, unitPrice: 4.99, subtotal: 4.99 }],
    subtotal: 4.99, shipping: 4.99, tax: 0.40, total: 10.38, status: 'delivered',
  },
  {
    id: 'ord_006', orderNumber: 'BJ-20241215', date: '2024-12-15T13:20:00Z',
    items: [{ product: products[12], quantity: 4, unitPrice: 4.99, subtotal: 19.96 }, { product: products[15], quantity: 2, unitPrice: 4.99, subtotal: 9.98 }],
    subtotal: 29.94, shipping: 4.99, tax: 2.39, total: 37.32, status: 'delivered',
  },
  {
    id: 'ord_007', orderNumber: 'BJ-20241201', date: '2024-12-01T10:45:00Z',
    items: [{ product: products[9], quantity: 3, unitPrice: 4.99, subtotal: 14.97 }],
    subtotal: 14.97, shipping: 4.99, tax: 1.20, total: 21.16, status: 'delivered',
  },
  {
    id: 'ord_008', orderNumber: 'BJ-20241120', date: '2024-11-20T17:30:00Z',
    items: [{ product: products[2], quantity: 2, unitPrice: 4.99, subtotal: 9.98 }],
    subtotal: 9.98, shipping: 4.99, tax: 0.80, total: 15.77, status: 'cancelled',
  },
  {
    id: 'ord_009', orderNumber: 'BJ-20250216', date: '2025-02-16T20:00:00Z',
    items: [{ product: products[5], quantity: 6, unitPrice: 4.99, subtotal: 29.94 }],
    subtotal: 29.94, shipping: 0, tax: 2.40, total: 32.34, status: 'pending',
  },
  {
    id: 'ord_010', orderNumber: 'BJ-20250130', date: '2025-01-30T15:10:00Z',
    items: [{ product: products[18], quantity: 2, unitPrice: 4.99, subtotal: 9.98 }, { product: products[21], quantity: 3, unitPrice: 4.99, subtotal: 14.97 }],
    subtotal: 24.95, shipping: 4.99, tax: 2.00, total: 31.94, status: 'delivered',
  },
  {
    id: 'ord_011', orderNumber: 'BJ-20250208', date: '2025-02-08T12:00:00Z',
    items: [{ product: products[14], quantity: 1, unitPrice: 4.99, subtotal: 4.99 }],
    subtotal: 4.99, shipping: 4.99, tax: 0.40, total: 10.38, status: 'delivered',
  },
]

export const transactions: Transaction[] = [
  { id: 'tx_001', date: '2025-02-17T10:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xabc123...def456', description: 'QR Scan Comp' },
  { id: 'tx_002', date: '2025-02-16T14:30:00Z', type: 'purchase', amount: -31.94, status: 'completed', description: 'Order BJ-20250215' },
  { id: 'tx_003', date: '2025-02-15T09:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xdef789...abc012', description: 'QR Scan Comp' },
  { id: 'tx_004', date: '2025-02-14T16:45:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0x111aaa...222bbb', description: 'QR Scan Comp' },
  { id: 'tx_005', date: '2025-02-13T11:20:00Z', type: 'affiliate', amount: 2.50, status: 'completed', txHash: '0x333ccc...444ddd', description: 'Referral Bonus - user92' },
  { id: 'tx_006', date: '2025-02-12T08:15:00Z', type: 'comp', amount: 5.00, status: 'completed', txHash: '0x555eee...666fff', description: 'VIP Tier Monthly Bonus' },
  { id: 'tx_007', date: '2025-02-10T17:00:00Z', type: 'purchase', amount: -26.95, status: 'completed', description: 'Order BJ-20250201' },
  { id: 'tx_008', date: '2025-02-08T13:30:00Z', type: 'withdrawal', amount: -50.00, status: 'completed', txHash: '0x777ggg...888hhh', description: 'Withdrawal to external wallet' },
  { id: 'tx_009', date: '2025-02-06T10:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0x999iii...000jjj', description: 'QR Scan Comp' },
  { id: 'tx_010', date: '2025-02-05T15:45:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xaaabbb...cccddd', description: 'QR Scan Comp' },
  { id: 'tx_011', date: '2025-02-04T09:30:00Z', type: 'affiliate', amount: 2.50, status: 'completed', txHash: '0xeeefff...000111', description: 'Referral Bonus - sarah_k' },
  { id: 'tx_012', date: '2025-02-03T12:00:00Z', type: 'comp', amount: 0.50, status: 'pending', txHash: '0x222333...444555', description: 'QR Scan Comp' },
  { id: 'tx_013', date: '2025-02-01T08:00:00Z', type: 'comp', amount: 10.00, status: 'completed', txHash: '0x666777...888999', description: 'Monthly VIP Bonus' },
  { id: 'tx_014', date: '2025-01-28T14:20:00Z', type: 'purchase', amount: -53.89, status: 'completed', description: 'Order BJ-20250102' },
  { id: 'tx_015', date: '2025-01-25T11:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xaaa111...bbb222', description: 'QR Scan Comp' },
  { id: 'tx_016', date: '2025-01-22T16:30:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xccc333...ddd444', description: 'QR Scan Comp' },
  { id: 'tx_017', date: '2025-01-20T09:45:00Z', type: 'withdrawal', amount: -25.00, status: 'completed', txHash: '0xeee555...fff666', description: 'Withdrawal to external wallet' },
  { id: 'tx_018', date: '2025-01-18T13:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0x111222...333444', description: 'QR Scan Comp' },
  { id: 'tx_019', date: '2025-01-15T10:30:00Z', type: 'affiliate', amount: 5.00, status: 'completed', txHash: '0x555666...777888', description: 'Referral Bonus - mike_d' },
  { id: 'tx_020', date: '2025-01-12T08:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0x999aaa...bbbccc', description: 'QR Scan Comp' },
  { id: 'tx_021', date: '2025-01-10T15:00:00Z', type: 'comp', amount: 0.50, status: 'completed', txHash: '0xdddee0...fff111', description: 'QR Scan Comp' },
  { id: 'tx_022', date: '2025-01-05T11:30:00Z', type: 'purchase', amount: -10.38, status: 'completed', description: 'Order BJ-20250118' },
]

export const channels: Channel[] = [
  { id: 'ch_001', name: 'General Chat', category: 'General', description: 'Open discussion for all members', tierRequired: 'standard', unreadCount: 5, icon: 'MessageCircle' },
  { id: 'ch_002', name: 'Introductions', category: 'General', description: 'New? Say hello!', tierRequired: 'standard', unreadCount: 0, icon: 'HandMetal' },
  { id: 'ch_003', name: 'Flavor Reviews', category: 'General', description: 'Share your thoughts on BlakJaks flavors', tierRequired: 'standard', unreadCount: 12, icon: 'Star' },
  { id: 'ch_004', name: 'VIP Lounge', category: 'High Roller Lounge', description: 'Exclusive VIP discussion', tierRequired: 'vip', unreadCount: 3, icon: 'Crown' },
  { id: 'ch_005', name: 'High Roller Table', category: 'High Roller Lounge', description: 'For High Roller tier and above', tierRequired: 'high_roller', unreadCount: 0, icon: 'Gem' },
  { id: 'ch_006', name: 'Whale Pod', category: 'High Roller Lounge', description: 'Whale-exclusive channel', tierRequired: 'whale', unreadCount: 0, icon: 'Trophy' },
  { id: 'ch_007', name: 'Comp Updates', category: 'Comps & Crypto', description: 'Latest comp award announcements', tierRequired: 'standard', unreadCount: 8, icon: 'Coins' },
  { id: 'ch_008', name: 'Wallet Help', category: 'Comps & Crypto', description: 'Questions about wallets and withdrawals', tierRequired: 'standard', unreadCount: 2, icon: 'Wallet' },
  { id: 'ch_009', name: 'Crypto Talk', category: 'Comps & Crypto', description: 'Discuss blockchain and crypto topics', tierRequired: 'standard', unreadCount: 0, icon: 'Bitcoin' },
  { id: 'ch_010', name: 'Proposals', category: 'Governance', description: 'Discuss and submit governance proposals', tierRequired: 'vip', unreadCount: 1, icon: 'FileText' },
  { id: 'ch_011', name: 'Voting Discussion', category: 'Governance', description: 'Discuss active votes', tierRequired: 'standard', unreadCount: 4, icon: 'Vote' },
]

const mockUsers = [
  { id: 'usr_010', username: 'cryptoQueen', tier: 'high_roller' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_010' },
  { id: 'usr_011', username: 'mintFanatic', tier: 'standard' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_011' },
  { id: 'usr_012', username: 'whaleDave', tier: 'whale' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_012' },
  { id: 'usr_013', username: 'newbie42', tier: 'standard' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_013' },
  { id: 'usr_014', username: 'vipSarah', tier: 'vip' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_014' },
  { id: 'usr_015', username: 'blazeRunner', tier: 'vip' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_015' },
  { id: 'usr_016', username: 'pouch_master', tier: 'high_roller' as const, avatarUrl: 'https://i.pravatar.cc/150?u=usr_016' },
]

function generateMessages(channelId: string, count: number): Message[] {
  const baseMessages = [
    'Has anyone tried the new Cinnamon flavor? Absolutely fire.',
    'Just hit 100 scans this quarter! VIP here I come.',
    'The comp system is so generous. Love getting USDT just for scanning.',
    'Anyone know when the next governance vote is?',
    'Wintergreen is still the GOAT flavor. Fight me.',
    'My withdrawal went through in like 2 minutes. Impressive.',
    'New member here! Excited to join the community.',
    'The transparency dashboard is sick. Love seeing where the money goes.',
    'Blue Razz + Coffee combo is underrated.',
    'Just referred 3 friends. The referral bonuses are legit.',
    'Who else is stacking comps for the long term?',
    'Spearmint 6mg is the perfect everyday pouch.',
    'The live stream last week was great. More of those please!',
    'Just submitted a governance proposal. Hope it gets approved!',
    'Love that we can actually vote on product decisions.',
    'Bubblegum flavor reminds me of childhood. In a good way.',
    'Anyone else notice the treasury utilization went up?',
    'High Roller lounge is where it\'s at.',
    'My order arrived in 2 days. Fast shipping!',
    'The QR scanning is so smooth on the app.',
    'Mint Ice is perfect for summer. Refreshing.',
    'Just hit Whale status! The grind was worth it.',
    'Does anyone know the comp rate for High Rollers?',
    'Citrus flavor is surprisingly good. Didn\'t expect to like it.',
    'The age verification process was quick and painless.',
    'Love the dark theme on the portal. Easy on the eyes.',
    'Just got my monthly tier bonus. Thanks BlakJaks!',
    'Coffee 6mg is my morning routine now.',
    'The community here is actually really chill.',
    'Governance voting makes me feel like my opinion matters.',
  ]

  const now = Date.now()
  return Array.from({ length: count }, (_, i) => {
    const user = i % 7 === 0
      ? { id: currentUser.id, username: currentUser.username, tier: currentUser.tier, avatarUrl: currentUser.avatarUrl }
      : mockUsers[i % mockUsers.length]
    return {
      id: `msg_${channelId}_${String(i + 1).padStart(3, '0')}`,
      channelId,
      userId: user.id,
      username: user.username,
      userTier: user.tier,
      content: baseMessages[i % baseMessages.length],
      timestamp: new Date(now - (count - i) * 300000).toISOString(),
      reactions: i % 4 === 0 ? { '\uD83D\uDD25': ['usr_010', 'usr_014'] } as Record<string, string[]> : {} as Record<string, string[]>,
      isSystem: false,
      avatarUrl: user.avatarUrl,
    }
  })
}

export const messagesByChannel: Record<string, Message[]> = {
  ch_001: generateMessages('ch_001', 35),
  ch_002: generateMessages('ch_002', 15),
  ch_003: generateMessages('ch_003', 30),
  ch_004: generateMessages('ch_004', 20),
  ch_005: generateMessages('ch_005', 10),
  ch_007: generateMessages('ch_007', 25),
  ch_008: generateMessages('ch_008', 18),
  ch_010: generateMessages('ch_010', 12),
  ch_011: generateMessages('ch_011', 22),
}

export const votes: Vote[] = [
  {
    id: 'vote_001', title: 'New Flavor: Mango Tango', description: 'Should BlakJaks release a mango-flavored pouch for summer 2025?',
    options: [
      { id: 'opt_1a', label: 'Yes, release it!', votes: 842 },
      { id: 'opt_1b', label: 'No, focus on existing flavors', votes: 156 },
      { id: 'opt_1c', label: 'Yes, but limited edition only', votes: 423 },
    ],
    deadline: '2025-03-01T00:00:00Z', status: 'active', totalVotes: 1421,
  },
  {
    id: 'vote_002', title: 'Comp Rate Adjustment Q2', description: 'Vote on the proposed comp rate increase for Q2 2025.',
    options: [
      { id: 'opt_2a', label: 'Increase by 10%', votes: 567 },
      { id: 'opt_2b', label: 'Increase by 20%', votes: 334 },
      { id: 'opt_2c', label: 'Keep current rates', votes: 189 },
    ],
    deadline: '2025-02-28T00:00:00Z', status: 'active', totalVotes: 1090,
  },
  {
    id: 'vote_003', title: 'Community Event: Vegas Meetup', description: 'Should we organize a BlakJaks community meetup in Las Vegas?',
    options: [
      { id: 'opt_3a', label: 'Definitely!', votes: 1203 },
      { id: 'opt_3b', label: 'Maybe later', votes: 245 },
      { id: 'opt_3c', label: 'Virtual event instead', votes: 389 },
    ],
    deadline: '2025-03-15T00:00:00Z', status: 'active', totalVotes: 1837,
  },
  {
    id: 'vote_004', title: 'Packaging Redesign', description: 'Vote on the proposed packaging redesign for 2025.',
    options: [
      { id: 'opt_4a', label: 'Design A - Minimal', votes: 890 },
      { id: 'opt_4b', label: 'Design B - Bold', votes: 1150 },
      { id: 'opt_4c', label: 'Keep current design', votes: 340 },
    ],
    deadline: '2025-01-31T00:00:00Z', status: 'closed', userVote: 'opt_4b', totalVotes: 2380,
  },
  {
    id: 'vote_005', title: 'Charity Partnership', description: 'Which charity should BlakJaks partner with for Q1 donations?',
    options: [
      { id: 'opt_5a', label: 'Ocean Cleanup', votes: 678 },
      { id: 'opt_5b', label: 'Mental Health Foundation', votes: 912 },
      { id: 'opt_5c', label: 'Youth Education Fund', votes: 445 },
    ],
    deadline: '2024-12-31T00:00:00Z', status: 'closed', userVote: 'opt_5b', totalVotes: 2035,
  },
]

export const proposals: Proposal[] = [
  { id: 'prop_001', title: 'Add Subscription Option', description: 'Allow members to subscribe for monthly auto-shipments at a discounted rate.', submittedBy: 'cryptoQueen', status: 'under_review', createdAt: '2025-02-10T10:00:00Z' },
  { id: 'prop_002', title: 'NFT Membership Cards', description: 'Create NFT-based membership cards that unlock exclusive perks.', submittedBy: 'whaleDave', status: 'approved', createdAt: '2025-01-20T14:00:00Z' },
  { id: 'prop_003', title: 'Multi-Language Support', description: 'Add support for Spanish, French, and German in the social hub.', submittedBy: 'vipSarah', status: 'submitted', createdAt: '2025-02-15T08:00:00Z' },
]

export const comps: CompAward[] = [
  { id: 'comp_001', date: '2025-02-17T10:00:00Z', amount: 0.50, type: 'scan', txHash: '0xabc123...def456', status: 'completed' },
  { id: 'comp_002', date: '2025-02-15T09:00:00Z', amount: 0.50, type: 'scan', txHash: '0xdef789...abc012', status: 'completed' },
  { id: 'comp_003', date: '2025-02-14T16:45:00Z', amount: 0.50, type: 'scan', txHash: '0x111aaa...222bbb', status: 'completed' },
  { id: 'comp_004', date: '2025-02-12T08:15:00Z', amount: 5.00, type: 'tier_bonus', txHash: '0x555eee...666fff', status: 'completed' },
  { id: 'comp_005', date: '2025-02-06T10:00:00Z', amount: 0.50, type: 'scan', txHash: '0x999iii...000jjj', status: 'completed' },
  { id: 'comp_006', date: '2025-02-01T08:00:00Z', amount: 10.00, type: 'tier_bonus', txHash: '0x666777...888999', status: 'completed' },
  { id: 'comp_007', date: '2025-01-25T11:00:00Z', amount: 0.50, type: 'scan', txHash: '0xaaa111...bbb222', status: 'completed' },
  { id: 'comp_008', date: '2025-01-18T13:00:00Z', amount: 0.50, type: 'scan', txHash: '0x111222...333444', status: 'completed' },
  { id: 'comp_009', date: '2025-02-03T12:00:00Z', amount: 0.50, type: 'scan', txHash: '0x222333...444555', status: 'pending' },
]

export const scans: Scan[] = Array.from({ length: 18 }, (_, i) => ({
  id: `scan_${String(i + 1).padStart(3, '0')}`,
  date: new Date(Date.now() - i * 86400000 * 2).toISOString(),
  qrCodeId: `QR-${String(1000 + i)}`,
  product: products[i % products.length].name,
}))

export const treasuryWallets: TreasuryWallet[] = [
  {
    name: 'Member Comp Pool',
    pool: 'member',
    balance: 2450000,
    address: '0x1234...abcd',
    utilization: 67,
    sparklineData: [2100000, 2150000, 2200000, 2180000, 2250000, 2300000, 2280000, 2320000, 2350000, 2380000, 2400000, 2420000, 2410000, 2430000, 2440000, 2435000, 2445000, 2450000, 2440000, 2455000, 2460000, 2450000, 2440000, 2445000, 2450000, 2455000, 2460000, 2458000, 2452000, 2450000],
  },
  {
    name: 'Affiliate Pool',
    pool: 'affiliate',
    balance: 245000,
    address: '0x5678...efgh',
    utilization: 42,
    sparklineData: [200000, 205000, 210000, 215000, 218000, 220000, 225000, 228000, 230000, 232000, 235000, 237000, 238000, 239000, 240000, 241000, 242000, 243000, 244000, 244500, 244800, 245000, 244500, 244800, 245000, 245200, 245100, 245000, 245000, 245000],
  },
  {
    name: 'Wholesale Pool',
    pool: 'wholesale',
    balance: 245000,
    address: '0x9abc...ijkl',
    utilization: 38,
    sparklineData: [210000, 215000, 218000, 220000, 222000, 225000, 228000, 230000, 232000, 234000, 235000, 236000, 237000, 238000, 239000, 240000, 241000, 242000, 243000, 243500, 244000, 244200, 244500, 244800, 245000, 245000, 245100, 245000, 245000, 245000],
  },
]

export const transparencyOverview: TransparencyOverview = {
  totalScans: 847523,
  monthlySales: 1250000,
  activeMembers: 24891,
  growthRate: 12.5,
}

export const activityFeed: ActivityFeedItem[] = [
  { id: 'af_001', message: 'You scanned a QR code and earned $0.50 USDT', timestamp: '2025-02-17T10:00:00Z', type: 'scan' },
  { id: 'af_002', message: 'Order BJ-20250215 is now processing', timestamp: '2025-02-16T16:45:00Z', type: 'order' },
  { id: 'af_003', message: 'New governance vote: "New Flavor: Mango Tango"', timestamp: '2025-02-16T12:00:00Z', type: 'governance' },
  { id: 'af_004', message: 'You earned $0.50 USDT from a QR scan', timestamp: '2025-02-15T09:00:00Z', type: 'comp' },
  { id: 'af_005', message: 'cryptoQueen mentioned you in #General Chat', timestamp: '2025-02-15T08:30:00Z', type: 'social' },
  { id: 'af_006', message: 'Order BJ-20250201 has shipped!', timestamp: '2025-02-14T12:00:00Z', type: 'order' },
  { id: 'af_007', message: 'You earned $0.50 USDT from a QR scan', timestamp: '2025-02-14T16:45:00Z', type: 'scan' },
  { id: 'af_008', message: 'You earned $2.50 referral bonus from user92', timestamp: '2025-02-13T11:20:00Z', type: 'comp' },
  { id: 'af_009', message: 'VIP Monthly Tier Bonus: $5.00 USDT', timestamp: '2025-02-12T08:15:00Z', type: 'comp' },
  { id: 'af_010', message: 'New message in #Flavor Reviews', timestamp: '2025-02-11T14:00:00Z', type: 'social' },
  { id: 'af_011', message: 'Order BJ-20250187 delivered!', timestamp: '2025-02-10T18:00:00Z', type: 'order' },
  { id: 'af_012', message: 'Withdrawal of $50.00 USDT completed', timestamp: '2025-02-08T13:30:00Z', type: 'comp' },
  { id: 'af_013', message: 'System maintenance completed successfully', timestamp: '2025-02-07T06:00:00Z', type: 'system' },
  { id: 'af_014', message: 'You scanned a QR code and earned $0.50 USDT', timestamp: '2025-02-06T10:00:00Z', type: 'scan' },
  { id: 'af_015', message: 'Governance vote "Packaging Redesign" closed', timestamp: '2025-02-01T00:00:00Z', type: 'governance' },
  { id: 'af_016', message: 'Monthly VIP Bonus: $10.00 USDT', timestamp: '2025-02-01T08:00:00Z', type: 'comp' },
  { id: 'af_017', message: 'New channel: #Crypto Talk is now available', timestamp: '2025-01-28T10:00:00Z', type: 'social' },
  { id: 'af_018', message: 'You earned $2.50 referral bonus from sarah_k', timestamp: '2025-01-25T11:00:00Z', type: 'comp' },
  { id: 'af_019', message: 'Order BJ-20250102 delivered!', timestamp: '2025-01-20T14:00:00Z', type: 'order' },
  { id: 'af_020', message: 'Withdrawal of $25.00 USDT completed', timestamp: '2025-01-20T09:45:00Z', type: 'comp' },
  { id: 'af_021', message: 'You earned $5.00 referral bonus from mike_d', timestamp: '2025-01-15T10:30:00Z', type: 'comp' },
]

export const monthlyEarnings: MonthlyEarning[] = [
  { month: 'Sep 2024', comps: 12.50, referrals: 5.00 },
  { month: 'Oct 2024', comps: 18.00, referrals: 7.50 },
  { month: 'Nov 2024', comps: 15.50, referrals: 10.00 },
  { month: 'Dec 2024', comps: 22.00, referrals: 12.50 },
  { month: 'Jan 2025', comps: 28.50, referrals: 15.00 },
  { month: 'Feb 2025', comps: 19.50, referrals: 7.50 },
]

export const compTierStats = [
  { tier: 'Standard', members: 18420, avgComp: 3.25, totalDistributed: 59865 },
  { tier: 'VIP', members: 4890, avgComp: 8.50, totalDistributed: 41565 },
  { tier: 'High Roller', members: 1340, avgComp: 18.75, totalDistributed: 25125 },
  { tier: 'Whale', members: 241, avgComp: 45.00, totalDistributed: 10845 },
]

export const partnerMetrics = {
  totalAffiliates: 342,
  activeAffiliates: 287,
  totalWholesalers: 48,
  activeWholesalers: 41,
  affiliatePayouts: 85400,
  wholesaleVolume: 3240000,
}

export const systemHealth = {
  uptime: 99.97,
  blockchainLatency: 1.2,
  apiResponseTime: 145,
  activeSessions: 3421,
  scanProcessingRate: 98.5,
  lastBlockSync: '2025-02-17T10:05:00Z',
}
