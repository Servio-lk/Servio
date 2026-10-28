import type { ReactNode } from 'react';
export function Field({label,children}:{label:string;children:ReactNode}) {
  return <label className="flex flex-col gap-1 text-sm font-medium"><span>{label}</span>{children}</label>;
}
export function Panel({title,children}:{title:string;children:ReactNode}) {
  return <section className="rounded-xl border border-black/10 bg-white p-5 space-y-4"><h2 className="text-lg font-semibold">{title}</h2>{children}</section>;
}
export function Feedback({error,message}:{error:string;message:string}) {
  return <div aria-live="polite">{error&&<p role="alert" className="rounded-lg bg-red-50 p-3 text-red-700">{error}</p>}{message&&<p className="rounded-lg bg-green-50 p-3 text-green-800">{message}</p>}</div>;
}
