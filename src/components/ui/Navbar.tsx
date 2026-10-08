"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { ArrowUpRight, Menu, X, Shield } from "lucide-react";

interface NavbarProps {
  onQuoteClick: () => void;
}

export function Navbar({ onQuoteClick }: NavbarProps) {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 40);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { label: "MAQUINARIA", href: "#maquinaria" },
    { label: "SERVICIOS", href: "#servicios" },
    { label: "PROYECTOS", href: "#proyectos" },
    { label: "NOSOTROS", href: "#nosotros" },
    { label: "CONTACTO", href: "#contacto" },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled
          ? "bg-[#15191C]/80 backdrop-blur-xl border-b border-[#252B2F]/60 py-4 shadow-2xl"
          : "bg-transparent py-6"
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 md:px-12 flex items-center justify-between">
        {/* LOGO */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-10 h-10 bg-[#080A0B] border border-[#F5B800]/40 rounded-lg flex items-center justify-center group-hover:border-[#F5B800] transition-colors duration-300 yellow-glow">
            <span className="font-heading font-black text-[#F5B800] text-xl tracking-tighter">
              O
            </span>
          </div>
          <div className="flex flex-col">
            <span className="font-heading font-extrabold text-2xl tracking-widest text-[#F5F6F3] group-hover:text-[#F5B800] transition-colors duration-300">
              ORVEXA
            </span>
            <span className="text-[9px] font-mono tracking-widest text-[#9BA2A6] uppercase -mt-1">
              HEAVY MACHINERY & INFRASTRUCTURE
            </span>
          </div>
        </Link>

        {/* DESKTOP MENU */}
        <nav className="hidden lg:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="text-xs font-mono tracking-widest text-[#9BA2A6] hover:text-[#F5B800] transition-colors duration-200 uppercase relative group py-1"
            >
              {link.label}
              <span className="absolute bottom-0 left-0 w-0 h-[2px] bg-[#F5B800] transition-all duration-300 group-hover:w-full" />
            </a>
          ))}
        </nav>

        {/* CTA BUTTON */}
        <div className="hidden lg:flex items-center gap-4">
          <button
            onClick={onQuoteClick}
            className="group relative inline-flex items-center gap-2 px-6 py-3 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-wider rounded transition-all duration-300 transform hover:-translate-y-0.5 shadow-lg hover:shadow-[#F5B800]/25"
          >
            <span>SOLICITAR COTIZACIÓN</span>
            <ArrowUpRight className="w-4 h-4 transition-transform duration-300 group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
          </button>
        </div>

        {/* MOBILE MENU TOGGLE */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="lg:hidden p-2 text-[#F5F6F3] hover:text-[#F5B800] transition-colors"
          aria-label="Toggle Navigation Menu"
        >
          {mobileMenuOpen ? <X className="w-7 h-7" /> : <Menu className="w-7 h-7" />}
        </button>
      </div>

      {/* MOBILE DROPDOWN */}
      {mobileMenuOpen && (
        <div className="lg:hidden bg-[#15191C]/95 backdrop-blur-2xl border-b border-[#252B2F] px-6 py-8 flex flex-col gap-6 animate-fadeIn">
          {navLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              onClick={() => setMobileMenuOpen(false)}
              className="text-sm font-mono tracking-widest text-[#F5F6F3] hover:text-[#F5B800] transition-colors uppercase border-b border-[#252B2F]/40 pb-3"
            >
              {link.label}
            </a>
          ))}
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              onQuoteClick();
            }}
            className="inline-flex items-center justify-center gap-2 px-6 py-4 bg-[#F5B800] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded shadow-xl mt-2"
          >
            <span>SOLICITAR COTIZACIÓN</span>
            <ArrowUpRight className="w-4 h-4" />
          </button>
        </div>
      )}
    </header>
  );
}
