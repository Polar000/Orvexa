"use client";

import React, { useEffect, useState } from "react";

export function CustomCursor() {
  const [pos, setPos] = useState({ x: -100, y: -100 });
  const [cursorText, setCursorText] = useState("");
  const [isHovered, setIsHovered] = useState(false);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    if (window.innerWidth < 1024) return; // Desktop only

    const handleMouseMove = (e: MouseEvent) => {
      setPos({ x: e.clientX, y: e.clientY });
      if (!isVisible) setIsVisible(true);

      const target = e.target as HTMLElement | null;
      if (!target) return;

      const interactiveEl = target.closest("[data-cursor]") as HTMLElement | null;
      if (interactiveEl) {
        setIsHovered(true);
        setCursorText(interactiveEl.getAttribute("data-cursor") || "");
      } else if (
        target.tagName === "BUTTON" ||
        target.tagName === "A" ||
        target.closest("button") ||
        target.closest("a")
      ) {
        setIsHovered(true);
        setCursorText("");
      } else {
        setIsHovered(false);
        setCursorText("");
      }
    };

    const handleMouseLeave = () => setIsVisible(false);

    window.addEventListener("mousemove", handleMouseMove);
    document.addEventListener("mouseleave", handleMouseLeave);

    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseleave", handleMouseLeave);
    };
  }, [isVisible]);

  if (!isVisible) return null;

  return (
    <div
      className="fixed top-0 left-0 pointer-events-none z-[9999] hidden lg:block transition-opacity duration-300"
      style={{
        transform: `translate3d(${pos.x}px, ${pos.y}px, 0)`,
      }}
    >
      <div
        className={`relative -translate-x-1/2 -translate-y-1/2 flex items-center justify-center rounded-full border transition-all duration-200 ease-out ${
          isHovered
            ? "w-16 h-16 bg-[#F5B800]/20 border-[#F5B800] backdrop-blur-sm scale-110"
            : "w-8 h-8 border-[#F5B800]/60 bg-[#080A0B]/40"
        }`}
      >
        {cursorText ? (
          <span className="text-[10px] font-mono font-bold tracking-widest text-[#F5B800] uppercase text-center px-1">
            {cursorText}
          </span>
        ) : (
          !isHovered && <div className="w-1.5 h-1.5 bg-[#F5B800] rounded-full" />
        )}
      </div>
    </div>
  );
}
