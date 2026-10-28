import { useRef, useState } from 'react';
export function useFinanceAction() {
  const [busy,setBusy]=useState(false),[error,setError]=useState(''),[message,setMessage]=useState('');
  const running=useRef(false);
  async function act(operation:()=>Promise<void>,success='Saved successfully') {
    if(running.current)return;
    running.current=true;setBusy(true);setError('');setMessage('');
    try { await operation();setMessage(success); } catch(e) { setError(e instanceof Error?e.message:'Request failed'); }
    finally {running.current=false;setBusy(false);}
  }
  return {busy,error,message,act};
}
export const inputClass='rounded-lg border border-black/15 bg-white px-3 py-2 min-w-0 w-full';
export const buttonClass='rounded-lg bg-[#ff5d2e] px-4 py-2 text-sm font-semibold text-white disabled:opacity-40';
export const secondaryClass='rounded-lg border border-black/15 bg-white px-3 py-2 text-sm font-medium disabled:opacity-40';
