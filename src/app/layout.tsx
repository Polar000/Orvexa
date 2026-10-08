import type { Metadata } from "next";
import { Space_Grotesk, Inter } from "next/font/google";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "ORVEXA | Maquinaria Pesada, Construcción e Infraestructura",
  description:
    "Maquinaria pesada, alquiler de equipos, construcción, perforación, movimiento de tierras y soluciones para proyectos solares.",
  keywords: [
    "Maquinaria Pesada",
    "Construcción",
    "Alquiler de Maquinaria",
    "Perforación",
    "Proyectos Solares",
    "Movimiento de Tierras",
    "ORVEXA",
  ],
  authors: [{ name: "ORVEXA Infrastructure Tech" }],
  openGraph: {
    title: "ORVEXA | Maquinaria Pesada, Construcción e Infraestructura",
    description:
      "THE POWER BEHIND THE PROJECT. Soluciones de alta ingeniería para proyectos de gran escala.",
    url: "https://orvexa.com",
    siteName: "ORVEXA",
    locale: "es_ES",
    type: "website",
  },
  icons: {
    icon: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className={`${spaceGrotesk.variable} ${inter.variable} scroll-smooth`}>
      <body className="bg-[#080A0B] text-[#F5F6F3] antialiased selection:bg-[#F5B800] selection:text-[#080A0B]">
        {children}
      </body>
    </html>
  );
}
