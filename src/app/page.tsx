"use client";

import React, { useState } from "react";
import { Navbar } from "@/components/ui/Navbar";
import { CustomCursor } from "@/components/ui/CustomCursor";
import { HeroSection } from "@/components/sections/HeroSection";
import { FleetShowroomSection } from "@/components/sections/FleetShowroomSection";
import { MachineShowcaseSection } from "@/components/sections/MachineShowcaseSection";
import { OrvexaWorldSection } from "@/components/sections/OrvexaWorldSection";
import { ServicesSection } from "@/components/sections/ServicesSection";
import { RentalSection } from "@/components/sections/RentalSection";
import { SolarInfrastructureSection } from "@/components/sections/SolarInfrastructureSection";
import { ConstructionSection } from "@/components/sections/ConstructionSection";
import { ProjectsSection } from "@/components/sections/ProjectsSection";
import { BrandStandardSection } from "@/components/sections/BrandStandardSection";
import { ContactSection } from "@/components/sections/ContactSection";
import { FLEET_CATALOG, EquipmentItem } from "@/data/fleet";

export default function Home() {
  const [selectedMachine, setSelectedMachine] = useState<EquipmentItem>(FLEET_CATALOG[0]);
  const [quoteTargetMachine, setQuoteTargetMachine] = useState<string>("");

  const handleQuoteClick = (machineName?: string) => {
    if (machineName) {
      setQuoteTargetMachine(machineName);
    }
    const contactElement = document.getElementById("contacto");
    if (contactElement) {
      contactElement.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <main className="relative bg-[#080A0B] text-[#F5F6F3] min-h-screen overflow-x-hidden selection:bg-[#F5B800] selection:text-[#080A0B]">
      {/* Custom Desktop Interactive Cursor */}
      <CustomCursor />

      {/* Glassmorphic Responsive Navbar */}
      <Navbar onQuoteClick={() => handleQuoteClick()} />

      {/* Hero Section with Interactive 3D Canvas */}
      <HeroSection onQuoteClick={() => handleQuoteClick()} />

      {/* 3D Fleet Showroom */}
      <FleetShowroomSection
        onSelectMachine={(machine) => setSelectedMachine(machine)}
        onQuoteClick={() => handleQuoteClick(selectedMachine.name)}
      />

      {/* Dynamic Machine Showcase */}
      <MachineShowcaseSection
        selectedMachine={selectedMachine}
        onQuoteClick={() => handleQuoteClick(selectedMachine.name)}
      />

      {/* ORVEXA World (Built for Scale) */}
      <OrvexaWorldSection />

      {/* Capabilities & Services ("What We Do") */}
      <ServicesSection onQuoteClick={() => handleQuoteClick()} />

      {/* Equipment Rental Marketplace */}
      <RentalSection onQuoteClick={(mName) => handleQuoteClick(mName)} />

      {/* Solar Energy Infrastructure */}
      <SolarInfrastructureSection onQuoteClick={() => handleQuoteClick("Solución Solar SL-500")} />

      {/* Civil & Heavy Construction Engineering */}
      <ConstructionSection />

      {/* Horizontal Projects Gallery */}
      <ProjectsSection />

      {/* The ORVEXA Standard ("Built Different") */}
      <BrandStandardSection />

      {/* Closing 3D Contact Section & Industrial Quote Panel */}
      <ContactSection initialMachine={quoteTargetMachine || selectedMachine.name} />
    </main>
  );
}
