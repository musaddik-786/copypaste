import { ShieldCheck } from "lucide-react";
import { AppSidebar } from "@/components/app-sidebar";

interface Props {
  active: string;
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  children: React.ReactNode;
  overlay?: React.ReactNode;
}

/** One frame for every screen: navy top bar, left navigation, page header, content on a light canvas. */
export function AppShell({ active, title, subtitle, actions, children, overlay }: Props) {
  return (
    <div className="flex h-screen w-full flex-col bg-background">
      <header className="flex h-12 shrink-0 items-center justify-between bg-[#0B2A4A] px-5 text-white">
        <div className="flex items-center gap-3">
          <div className="flex h-7 w-7 items-center justify-center rounded-md bg-primary text-sm font-bold">H</div>
          <span className="text-sm font-semibold tracking-wide">Hexaware <span className="text-sky-300">AMS</span></span>
          <span className="hidden h-4 w-px bg-white/25 sm:inline-block" />
          <span className="hidden text-sm text-white/70 sm:inline">Guidewire Application Support</span>
        </div>
        <span className="flex items-center gap-1.5 text-xs text-white/70"><ShieldCheck className="h-4 w-4" aria-hidden />Production support</span>
      </header>
      <div className="flex min-h-0 flex-1">
        <AppSidebar activeItem={active} />
        <main className="flex-1 overflow-y-auto bg-background">
          <div className="mx-auto max-w-[1400px] px-8 py-6">
            <div className="mb-6 flex flex-wrap items-end justify-between gap-4 border-b border-border pb-4">
              <div>
                <h1 className="text-2xl font-bold tracking-tight text-[#0B2A4A]">{title}</h1>
                {subtitle && <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>}
              </div>
              {actions}
            </div>
            {children}
          </div>
        </main>
      </div>
      {overlay}
    </div>
  );
}
