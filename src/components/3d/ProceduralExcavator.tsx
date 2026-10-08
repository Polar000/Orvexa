"use client";

import React, { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

interface MachineryProps {
  colorAccent?: string;
  hovered?: boolean;
  mousePos?: { x: number; y: number };
}

export function ProceduralExcavator({
  colorAccent = "#F5B800",
  hovered = false,
  mousePos = { x: 0, y: 0 },
}: MachineryProps) {
  const cabinGroupRef = useRef<THREE.Group>(null);
  const boomRef = useRef<THREE.Group>(null);
  const armRef = useRef<THREE.Group>(null);
  const bucketRef = useRef<THREE.Group>(null);

  useFrame((state) => {
    const time = state.clock.getElapsedTime();

    if (cabinGroupRef.current) {
      // Gentle idle motion + mouse rotation tracking
      const targetRotationY = (mousePos.x * 0.25) + Math.sin(time * 0.8) * 0.03;
      cabinGroupRef.current.rotation.y = THREE.MathUtils.lerp(
        cabinGroupRef.current.rotation.y,
        targetRotationY,
        0.05
      );
    }

    if (boomRef.current) {
      // Subdued boom movement
      const targetBoomX = -0.2 + (mousePos.y * 0.1) + Math.sin(time * 1.2) * 0.02;
      boomRef.current.rotation.x = THREE.MathUtils.lerp(
        boomRef.current.rotation.x,
        targetBoomX,
        0.05
      );
    }

    if (armRef.current) {
      const targetArmX = 0.5 + Math.cos(time * 1.2) * 0.03;
      armRef.current.rotation.x = THREE.MathUtils.lerp(
        armRef.current.rotation.x,
        targetArmX,
        0.05
      );
    }
  });

  // Materials
  const darkMetal = (
    <meshStandardMaterial
      color="#15191C"
      roughness={0.3}
      metalness={0.8}
    />
  );
  const yellowPaint = (
    <meshStandardMaterial
      color={colorAccent}
      roughness={0.2}
      metalness={0.6}
    />
  );
  const chromeMetal = (
    <meshStandardMaterial
      color="#E0E0E0"
      roughness={0.1}
      metalness={0.95}
    />
  );
  const glassMat = (
    <meshPhysicalMaterial
      color="#0D131A"
      roughness={0.1}
      transmission={0.85}
      thickness={0.5}
      transparent
      opacity={0.7}
    />
  );
  const trackMat = (
    <meshStandardMaterial
      color="#0A0C0E"
      roughness={0.8}
      metalness={0.4}
    />
  );

  return (
    <group position={[0, -0.6, 0]} scale={1.1}>
      {/* UNDERCARRIAGE & TRACKS */}
      <group position={[0, 0.4, 0]}>
        {/* Left Track */}
        <mesh position={[-1.3, 0, 0]} castShadow receiveShadow>
          <boxGeometry args={[0.5, 0.65, 3.8]} />
          {trackMat}
        </mesh>
        {/* Left Track Wheels */}
        {[-1.4, -0.7, 0, 0.7, 1.4].map((z, i) => (
          <mesh key={`ltw-${i}`} position={[-1.3, 0, z]} rotation={[0, 0, Math.PI / 2]}>
            <cylinderGeometry args={[0.25, 0.25, 0.55, 16]} />
            {darkMetal}
          </mesh>
        ))}

        {/* Right Track */}
        <mesh position={[1.3, 0, 0]} castShadow receiveShadow>
          <boxGeometry args={[0.5, 0.65, 3.8]} />
          {trackMat}
        </mesh>
        {/* Right Track Wheels */}
        {[-1.4, -0.7, 0, 0.7, 1.4].map((z, i) => (
          <mesh key={`rtw-${i}`} position={[1.3, 0, z]} rotation={[0, 0, Math.PI / 2]}>
            <cylinderGeometry args={[0.25, 0.25, 0.55, 16]} />
            {darkMetal}
          </mesh>
        ))}

        {/* Central Chassis Axle */}
        <mesh position={[0, 0.1, 0]} castShadow>
          <boxGeometry args={[2.2, 0.45, 2.2]} />
          {darkMetal}
        </mesh>

        {/* Slewing Ring / Slew Center */}
        <mesh position={[0, 0.4, 0]}>
          <cylinderGeometry args={[0.9, 0.9, 0.2, 32]} />
          {darkMetal}
        </mesh>
      </group>

      {/* ROTATING CABIN & UPPERSTRUCTURE */}
      <group ref={cabinGroupRef} position={[0, 0.9, 0]}>
        {/* Main Counterweight Body */}
        <mesh position={[0, 0.6, -0.5]} castShadow receiveShadow>
          <boxGeometry args={[2.5, 1.1, 2.6]} />
          {darkMetal}
        </mesh>

        {/* Counterweight Back Block with Yellow ORVEXA Accent */}
        <mesh position={[0, 0.6, -1.75]} castShadow>
          <boxGeometry args={[2.4, 0.9, 0.3]} />
          {yellowPaint}
        </mesh>

        {/* Cabin Structure */}
        <group position={[-0.75, 1.0, 0.2]}>
          <mesh castShadow receiveShadow>
            <boxGeometry args={[0.95, 1.2, 1.3]} />
            {darkMetal}
          </mesh>
          {/* Glass Windows */}
          <mesh position={[0, 0.1, 0.66]}>
            <planeGeometry args={[0.85, 0.9]} />
            {glassMat}
          </mesh>
          <mesh position={[-0.48, 0.1, 0]} rotation={[0, -Math.PI / 2, 0]}>
            <planeGeometry args={[1.1, 0.9]} />
            {glassMat}
          </mesh>
          <mesh position={[0.48, 0.1, 0]} rotation={[0, Math.PI / 2, 0]}>
            <planeGeometry args={[1.1, 0.9]} />
            {glassMat}
          </mesh>
          {/* Cabin Headlights */}
          <mesh position={[0, 0.55, 0.66]}>
            <boxGeometry args={[0.7, 0.12, 0.08]} />
            <meshStandardMaterial color="#FFFFFF" emissive="#FFD23F" emissiveIntensity={2} />
          </mesh>
        </group>

        {/* Engine Hood / Deck Top */}
        <mesh position={[0.4, 1.1, -0.4]} castShadow>
          <boxGeometry args={[1.1, 0.3, 1.8]} />
          {yellowPaint}
        </mesh>

        {/* Exhaust Pipe */}
        <mesh position={[0.7, 1.5, -1.0]}>
          <cylinderGeometry args={[0.07, 0.07, 0.7, 16]} />
          {darkMetal}
        </mesh>

        {/* MAIN BOOM (Articulated Primary Arm) */}
        <group ref={boomRef} position={[0.4, 0.8, 0.6]}>
          {/* Primary Curved Boom */}
          <mesh position={[0, 1.2, 1.0]} rotation={[-0.4, 0, 0]} castShadow>
            <boxGeometry args={[0.32, 2.6, 0.45]} />
            {yellowPaint}
          </mesh>
          <mesh position={[0, 2.3, 2.0]} rotation={[0.4, 0, 0]} castShadow>
            <boxGeometry args={[0.28, 1.8, 0.4]} />
            {yellowPaint}
          </mesh>

          {/* Hydraulic Cylinder Boom Base */}
          <mesh position={[0, 0.7, 0.4]} rotation={[-0.5, 0, 0]}>
            <cylinderGeometry args={[0.08, 0.08, 1.5, 16]} />
            {darkMetal}
          </mesh>
          <mesh position={[0, 1.1, 0.6]} rotation={[-0.5, 0, 0]}>
            <cylinderGeometry args={[0.05, 0.05, 1.4, 16]} />
            {chromeMetal}
          </mesh>

          {/* SECONDARY ARM (Dipper) */}
          <group ref={armRef} position={[0, 2.9, 2.6]}>
            <mesh position={[0, -0.9, 0.6]} rotation={[0.6, 0, 0]} castShadow>
              <boxGeometry args={[0.24, 2.2, 0.35]} />
              {yellowPaint}
            </mesh>

            {/* Arm Hydraulic Cylinder */}
            <mesh position={[0, 0.2, 0.1]} rotation={[0.2, 0, 0]}>
              <cylinderGeometry args={[0.06, 0.06, 1.2, 16]} />
              {darkMetal}
            </mesh>
            <mesh position={[0, -0.3, 0.3]} rotation={[0.2, 0, 0]}>
              <cylinderGeometry args={[0.04, 0.04, 1.2, 16]} />
              {chromeMetal}
            </mesh>

            {/* BUCKET */}
            <group ref={bucketRef} position={[0, -1.8, 1.3]} rotation={[-0.6, 0, 0]}>
              {/* Heavy Excavation Bucket Shell */}
              <mesh position={[0, -0.2, 0.2]} castShadow>
                <boxGeometry args={[0.85, 0.7, 0.8]} />
                {darkMetal}
              </mesh>
              {/* Bucket Teeth */}
              {[-0.32, -0.16, 0, 0.16, 0.32].map((x, i) => (
                <mesh key={`bt-${i}`} position={[x, -0.5, 0.55]} rotation={[0.4, 0, 0]}>
                  <coneGeometry args={[0.05, 0.22, 4]} />
                  {yellowPaint}
                </mesh>
              ))}
            </group>
          </group>
        </group>
      </group>
    </group>
  );
}
