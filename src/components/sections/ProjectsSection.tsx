"use client";

import React, { useRef } from "react";
import { ArrowLeft, ArrowRight, FolderGit2, MapPin, ShieldCheck, Tag } from "lucide-react";
import { PROJECTS, ProjectItem } from "@/data/projects";

export function ProjectsSection() {
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const scroll = (direction: "left" | "right") => {
    if (scrollContainerRef.current) {
      const scrollAmount = direction === "left" ? -450 : 450;
      scrollContainerRef.current.scrollBy({ left: scrollAmount, behavior: "smooth" });
    }
  };

  return (
    <section id="proyectos" className="relative w-full bg-[#15191C] py-28 border-t border-[#252B2F]/60 overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 md:px-12">
        {/* HEADER */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
          <div className="space-y-3 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-[#252B2F] border border-[#F5B800]/30 rounded text-[10px] font-mono tracking-widest text-[#F5B800] uppercase font-bold">
              <FolderGit2 className="w-3.5 h-3.5" /> PROYECTOS / CASE STUDIES
            </div>
            <h2 className="font-heading text-5xl sm:text-7xl font-extrabold text-[#F5F6F3] uppercase tracking-tighter">
              PROJECTS
            </h2>
            <p className="text-base sm:text-lg text-[#9BA2A6] font-sans font-light">
              Donde la maquinaria pesada se convierte en resultados tangibles de alta ingeniería.
            </p>
          </div>

          {/* GALLERY NAVIGATION BUTTONS */}
          <div className="flex items-center gap-3">
            <button
              onClick={() => scroll("left")}
              className="p-3 bg-[#080A0B] hover:bg-[#F5B800] text-[#F5F6F3] hover:text-[#080A0B] border border-[#252B2F] rounded-full transition-colors duration-300"
              aria-label="Scroll Left"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <button
              onClick={() => scroll("right")}
              className="p-3 bg-[#080A0B] hover:bg-[#F5B800] text-[#F5F6F3] hover:text-[#080A0B] border border-[#252B2F] rounded-full transition-colors duration-300"
              aria-label="Scroll Right"
            >
              <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* HORIZONTAL SCROLL CONTAINER */}
        <div
          ref={scrollContainerRef}
          className="flex gap-6 overflow-x-auto pb-8 pt-2 scrollbar-none snap-x snap-mandatory"
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          {PROJECTS.map((project) => (
            <div
              key={project.id}
              data-cursor="VIEW"
              className="snap-start shrink-0 w-[320px] sm:w-[480px] lg:w-[560px] bg-[#080A0B] border border-[#252B2F] rounded-3xl p-8 flex flex-col justify-between hover:border-[#F5B800]/60 transition-all duration-300 shadow-2xl relative group"
            >
              <div className="space-y-6">
                {/* PROJECT CODE & STATUS */}
                <div className="flex items-center justify-between border-b border-[#252B2F] pb-4">
                  <span className="text-xs font-mono text-[#F5B800] font-bold tracking-widest uppercase">
                    {project.code}
                  </span>
                  <span className="text-[10px] font-mono tracking-widest uppercase bg-[#15191C] px-2.5 py-1 rounded text-[#9BA2A6] border border-[#252B2F]">
                    {project.status === "COMPLETED" ? "EJECUTADO" : "EN DESARROLLO"}
                  </span>
                </div>

                {/* MEDIA PLACEHOLDER / GRAPHIC CARD */}
                <div className="h-48 bg-[#15191C] border border-[#252B2F] rounded-2xl p-6 flex flex-col justify-end relative overflow-hidden group-hover:border-[#F5B800]/40 transition-colors">
                  <div className="absolute top-4 right-4 flex items-center gap-1.5 px-3 py-1 bg-[#080A0B]/80 rounded text-[10px] font-mono text-[#9BA2A6]">
                    <MapPin className="w-3.5 h-3.5 text-[#F5B800]" />
                    <span>{project.location}</span>
                  </div>

                  <span className="text-xs font-mono text-[#F5B800] uppercase font-bold tracking-wider">
                    {project.type}
                  </span>
                </div>

                {/* TITLE & DESCRIPTION */}
                <div>
                  <h3 className="font-heading text-2xl font-extrabold text-[#F5F6F3] uppercase tracking-tight group-hover:text-[#F5B800] transition-colors">
                    {project.title}
                  </h3>
                  <p className="text-xs text-[#9BA2A6] mt-3 font-sans leading-relaxed line-clamp-3">
                    {project.description}
                  </p>
                </div>

                {/* METRICS */}
                <div className="grid grid-cols-3 gap-2 border-y border-[#252B2F] py-4">
                  {project.stats.map((st, i) => (
                    <div key={i}>
                      <span className="text-[9px] font-mono text-[#9BA2A6] uppercase block truncate">
                        {st.label}
                      </span>
                      <span className="text-xs font-mono font-bold text-[#F5F6F3]">
                        {st.value}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* MACHINERY DEPLOYED TAGS */}
              <div className="pt-4 flex flex-wrap gap-2">
                {project.machineryDeployed.map((m, i) => (
                  <span key={i} className="text-[10px] font-mono text-[#9BA2A6] bg-[#15191C] px-2 py-1 rounded border border-[#252B2F]">
                    {m}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
