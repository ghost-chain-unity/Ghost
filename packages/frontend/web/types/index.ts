export interface User {
  id: string;
  address: string;
  username?: string;
}

export interface Transaction {
  id: string;
  hash: string;
  from: string;
  to: string;
  value: string;
  timestamp: number;
}
