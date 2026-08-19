import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BarberOS — Modern barbershop management",
  description: "Booking, customer memory, Telegram automation and barber CRM in one platform.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
