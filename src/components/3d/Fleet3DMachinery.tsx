"use client";

import React, { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

interface FleetMachineProps {
  type: 'excavator' | 'bobcat' | 'backhoe' | 'drill' | 'solar_rig';
  colorAccent?: string;
}

export function Fleet3DMachinery({ type, colorAccent = "#F5B800" }: FleetMachineProps) {
  const groupRef = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = state.clock.getElapsedTime() * 0.25;
    }
  });

  const darkMetal = <meshStandardMaterial color="#15191C" roughness={0.3} metalness={0.8} />;
  const yellowPaint = <meshStandardMaterial color={colorAccent} roughness={0.2} metalness={0.6} />;
  const chromeMetal = <meshStandardMaterial color="#E0E0E0" roughness={0.1} metalness={0.95} />;

  if (type === 'bobcat') {
    return (
      <group ref={groupRef} position={[0, -0.4, 0]} scale={1.2}>
        {/* Bobcat Compact Body */}
        <mesh position={[0, 0.4, 0]} castShadow>
          <boxGeometry args={[1.4, 1.2, 2.0]} />
          {darkMetal}
        </mesh>
        {/* Cab Roof / Roll Cage */}
        <mesh position={[0, 1.2, -0.1]} castShadow>
          <boxGeometry args={[1.2, 0.9, 1.2]} />
          {yellowPaint}
        </mesh>
        {/* Wheels / Orugas */}
        {[-0.85, 0.85].map((x, i) => (
          <group key={`bc-side-${i}`} position={[x, 0.25, 0]}>
            <mesh rotation={[0, 0, Math.PI / 2]} castShadow>
              <cylinderGeometry args={[0.35, 0.35, 0.35, 24]} />
              {darkMetal}
            </mesh>
          </group>
        ))}
        {/* Loader Arms & Front Bucket */}
        <mesh position={[0, 0.5, 1.2]} castShadow>
          <boxGeometry args={[1.5, 0.5, 0.7]} />
          {yellowPaint}
        </mesh>
      </group>
    );
  }

  if (type === 'backhoe') {
    return (
      <group ref={groupRef} position={[0, -0.5, 0]} scale={1.1}>
        {/* Main Tractor Chassis */}
        <mesh position={[0, 0.6, 0]} castShadow>
          <boxGeometry args={[1.6, 1.1, 2.8]} />
          {yellowPaint}
        </mesh>
        {/* Large Rear Wheels */}
        {[-0.95, 0.95].map((x, i) => (
          <mesh key={`bh-rw-${i}`} position={[x, 0.5, -0.7]} rotation={[0, 0, Math.PI / 2]} castShadow>
            <cylinderGeometry args={[0.55, 0.55, 0.4, 24]} />
            {darkMetal}
          </mesh>
        ))}
        {/* Smaller Front Wheels */}
        {[-0.9, 0.9].map((x, i) => (
          <mesh key={`bh-fw-${i}`} position={[x, 0.35, 0.9]} rotation={[0, 0, Math.PI / 2]} castShadow>
            <cylinderGeometry args={[0.35, 0.35, 0.3, 24]} />
            {darkMetal}
          </mesh>
        ))}
        {/* Front Loader Bucket */}
        <mesh position={[0, 0.35, 1.7]} castShadow>
          <boxGeometry args={[1.8, 0.6, 0.8]} />
          {darkMetal}
        </mesh>
        {/* Rear Excavator Boom */}
        <group position={[0, 0.8, -1.6]}>
          <mesh position={[0, 0.8, -0.6]} rotation={[-0.4, 0, 0]} castShadow>
            <boxGeometry args={[0.25, 1.6, 0.3]} />
            {yellowPaint}
          </mesh>
          <mesh position={[0, 1.4, -1.1]} castShadow>
            <boxGeometry args={[0.6, 0.5, 0.5]} />
            {darkMetal}
          </mesh>
        </group>
      </group>
    );
  }

  if (type === 'drill') {
    return (
      <group ref={groupRef} position={[0, -0.6, 0]} scale={1.0}>
        {/* Heavy Drill Rig Crawler Base */}
        <mesh position={[0, 0.3, 0]} castShadow>
          <boxGeometry args={[2.2, 0.5, 3.2]} />
          {darkMetal}
        </mesh>
        {/* Machine Deck */}
        <mesh position={[0, 0.8, -0.2]} castShadow>
          <boxGeometry args={[2.0, 0.8, 2.2]} />
          {darkMetal}
        </mesh>
        {/* Vertical Drilling Mast / Tower */}
        <mesh position={[0, 2.6, 0.8]} castShadow>
          <boxGeometry args={[0.45, 4.2, 0.5]} />
          {yellowPaint}
        </mesh>
        {/* Rotary Drill Head & Kelly Bar */}
        <mesh position={[0, 2.2, 0.8]} castShadow>
          <cylinderGeometry args={[0.22, 0.22, 3.8, 24]} />
          {chromeMetal}
        </mesh>
        <mesh position={[0, 0.3, 0.8]} castShadow>
          <coneGeometry args={[0.35, 0.8, 16]} />
          {darkMetal}
        </mesh>
      </group>
    );
  }

  if (type === 'solar_rig') {
    return (
      <group ref={groupRef} position={[0, -0.5, 0]} scale={1.1}>
        {/* Crawler Base */}
        <mesh position={[0, 0.3, 0]} castShadow>
          <boxGeometry args={[1.8, 0.45, 2.4]} />
          {darkMetal}
        </mesh>
        {/* Hydraulic Piling Mast */}
        <mesh position={[0, 1.8, 0.6]} rotation={[-0.1, 0, 0]} castShadow>
          <boxGeometry args={[0.35, 3.2, 0.35]} />
          {yellowPaint}
        </mesh>
        {/* Hydraulic Drop Hammer */}
        <mesh position={[0, 2.0, 0.6]} castShadow>
          <boxGeometry args={[0.5, 0.7, 0.5]} />
          {darkMetal}
        </mesh>
        {/* Representative Solar Panel Frame Support */}
        <group position={[0, 1.2, -0.8]} rotation={[0.5, 0, 0]}>
          <mesh castShadow>
            <boxGeometry args={[2.4, 0.05, 1.4]} />
            <meshStandardMaterial color="#1E293B" roughness={0.2} metalness={0.9} />
          </mesh>
        </group>
      </group>
    );
  }

  // Default Fallback: Excavator
  return (
    <group ref={groupRef} position={[0, -0.5, 0]} scale={1.0}>
      <mesh position={[0, 0.4, 0]} castShadow>
        <boxGeometry args={[2.0, 0.6, 3.0]} />
        {darkMetal}
      </mesh>
      <mesh position={[0, 1.0, -0.2]} castShadow>
        <boxGeometry args={[1.8, 0.9, 1.8]} />
        {yellowPaint}
      </mesh>
      <mesh position={[0.4, 1.8, 0.8]} rotation={[-0.4, 0, 0]} castShadow>
        <boxGeometry args={[0.3, 2.0, 0.3]} />
        {yellowPaint}
      </mesh>
    </group>
  );
}
