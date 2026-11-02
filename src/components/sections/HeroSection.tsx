"use client";

import React, { useState, useEffect } from "react";
import { Canvas } from "@react-three/fiber";
import { ArrowRight, ChevronDown, Cpu, Zap } from "lucide-react";
import { Fleet3DMachinery } from "@/components/3d/Fleet3DMachinery";
import { IndustrialTerrain } from "@/components/3d/IndustrialTerrain";
import { WebGLErrorBoundary } from "@/components/3d/WebGLErrorBoundary";

interface HeroSectionProps {
  onQuoteClick: () => void;
}

export function HeroSection({ onQuoteClick }: HeroSectionProps) {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      const x = (e.clientX / window.innerWidth) * 2 - 1;
      const y = -(e.clientY / window.innerHeight) * 2 + 1;
      setMousePos({ x, y });
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, []);

  return (
    <section className="relative w-full min-h-screen bg-[#080A0B] flex flex-col justify-between overflow-hidden pt-28 pb-12">
      {/* BACKGROUND 3D CANVAS EXPERIENCE */}
      <div className="absolute inset-0 z-0">
        <WebGLErrorBoundary>
          <Canvas
            shadows
            camera={{ position: [0, 2.2, 7.5], fov: 42 }}
            gl={{ antialias: true, alpha: false }}
          >
            <color attach="background" args={["#080A0B"]} />
            <fog attach="fog" args={["#080A0B", 8, 22]} />

            {/* Cinematic Lighting Setup */}
            <ambientLight intensity={0.4} />
            <directionalLight
              position={[8, 12, 6]}
              intensity={2.2}
              color="#FFFFFF"
              castShadow
              shadow-mapSize-width={1024}
              shadow-mapSize-height={1024}
            />
            {/* Industrial Yellow Spotlight Accent */}
            <spotLight
              position={[-6, 8, -4]}
              intensity={4.5}
              color="#F5B800"
              angle={0.6}
              penumbra={0.8}
            />
            <pointLight position={[0, 4, 2]} intensity={1.5} color="#FFD23F" />

            {/* 3D Main Scene Content featuring Hincadora HWL600R */}
            <Fleet3DMachinery type="solar_rig" colorAccent="#F5B800" />
            <IndustrialTerrain showSolarPanels={true} />
          </Canvas>
        </WebGLErrorBoundary>

        {/* Ambient Dark Gradient Overlays for Readability */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#080A0B] via-transparent to-[#080A0B]/80 pointer-events-none" />
        <div className="absolute inset-0 bg-gradient-to-r from-[#080A0B] via-[#080A0B]/50 to-transparent pointer-events-none max-w-3xl" />
      </div>

      {/* HERO FOREGROUND CONTENT */}
      <div className="relative z-10 max-w-7xl mx-auto px-6 md:px-12 w-full my-auto py-12">
        <div className="max-w-3xl space-y-8">
          {/* BADGE */}
          <div className="inline-flex items-center gap-3 px-4 py-2 bg-[#15191C]/90 border border-[#F5B800]/40 rounded-full backdrop-blur-md">
            <span className="w-2 h-2 rounded-full bg-[#F5B800] animate-ping" />
            <span className="text-[11px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
              ORVEXA / HINCADORA HWL600R, BOBCAT & SERVICIOS
            </span>
          </div>

          {/* GIANT TITLE */}
          <h1 className="font-heading text-5xl sm:text-7xl lg:text-8xl xl:text-9xl font-extrabold text-[#F5F6F3] tracking-tighter leading-[0.88] uppercase">
            MOVEMOS <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#F5F6F3] via-[#F5B800] to-[#FFD23F]">
              LO QUE
            </span>{" "}
            <br />
            IMPORTA.
          </h1>

          {/* SUBTEXT */}
          <p className="text-lg sm:text-xl text-[#9BA2A6] max-w-xl font-sans font-light leading-relaxed">
            Especialistas en hincado solar fotovoltaico con Hincadora HWL600R, minicargador Bobcat y prestaci&#243;n integral de servicios de infraestructura y construcci&#243;n.
          </p>

          {/* BUTTONS */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 pt-4">
            <a
              href="#maquinaria"
              data-cursor="EXPLORE"
              className="group inline-flex items-center justify-center gap-3 px-8 py-4 bg-[#F5B800] hover:bg-[#FFD23F] text-[#080A0B] font-mono font-bold text-xs uppercase tracking-widest rounded transition-all duration-300 transform hover:-translate-y-0.5 shadow-xl hover:shadow-[#F5B800]/30"
            >
              <span>VER EQUIPOS Y SERVICIOS</span>
              <ArrowRight className="w-4 h-4 transition-transform duration-300 group-hover:translate-x-1" />
            </a>

            <button
              onClick={onQuoteClick}
              className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-[#15191C]/90 hover:bg-[#252B2F] border border-[#F5F6F3]/15 hover:border-[#F5B800]/50 text-[#F5F6F3] font-mono font-bold text-xs uppercase tracking-widest rounded backdrop-blur-md transition-all duration-300"
            >
              <span>SOLICITAR COTIZACIÓN</span>
            </button>
          </div>
        </div>
      </div>

      {/* FOOTER BAR WITH SCROLL INDICATOR */}
      <div className="relative z-10 max-w-7xl mx-auto px-6 md:px-12 w-full flex flex-col md:flex-row items-center justify-between gap-4 border-t border-[#252B2F]/40 pt-6">
        <div className="flex items-center gap-6 text-xs font-mono text-[#9BA2A6]">
          <span className="flex items-center gap-2">
            <Zap className="w-4 h-4 text-[#F5B800]" />
            HINCADO SOLAR HWL600R & BOBCAT COMPACT
          </span>
          <span className="hidden sm:inline text-[#252B2F]">|</span>
          <span className="hidden sm:inline">PRESTACIÓN DE SERVICIOS INDUSTRIALES</span>
        </div>

        {/* SCROLL INDICATOR */}
        <a
          href="#maquinaria"
          className="flex items-center gap-2 text-xs font-mono text-[#9BA2A6] hover:text-[#F5B800] transition-colors tracking-widest uppercase group"
        >
          <span>SCROLL TO EXPLORE</span>
          <ChevronDown className="w-4 h-4 text-[#F5B800] animate-bounce" />
        </a>
      </div>
    </section>
  );
}
