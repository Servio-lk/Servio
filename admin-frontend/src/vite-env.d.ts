/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
  // more env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

// PayHere JavaScript SDK global — injected via index.html script tag
interface PayHerePayment {
  sandbox: boolean;
  merchant_id: string;
  return_url: undefined;
  cancel_url: undefined;
  notify_url: string;
  order_id: string;
  items: string;
  amount: string;
  currency: string;
  hash: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  country: string;
  [key: string]: unknown;
}

interface Window {
  payhere: {
    onCompleted: (orderId: string) => void;
    onDismissed: () => void;
    onError: (error: string) => void;
    startPayment: (payment: PayHerePayment) => void;
  };
}
