import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Terminal, Shield, Cpu, Zap, ArrowDown } from 'lucide-react';
import heroImage from 'figma:asset/788c8a1e233d9d9c3679e81e0171f3403f8d2df1.png';

const PERSONAS = {
  hacker: {
    id: 'hacker',
    title: 'THE SHADOW',
    serif: 'Infiltrator',
    description: 'Securing the unseen layer. Low-level optimization and penetration testing for high-stakes infrastructure.',
    color: 'text-emerald-400',
    icon: <Terminal className="w-5 h-5" />
  },
  leader: {
    id: 'leader',
    title: 'THE CORE',
    serif: 'Architect',
    description: 'The convergence point of logic and aesthetics. Architecting scalable digital systems from foundation to finish.',
    color: 'text-amber-400',
    icon: <Shield className="w-5 h-5" />
  },
  ai: {
    id: 'ai',
    title: 'THE NEURAL',
    serif: 'Visionary',
    description: 'Autonomous systems and predictive modeling. Integrating artificial intelligence into human-centric experiences.',
    color: 'text-indigo-400',
    icon: <Cpu className="w-5 h-5" />
  }
};

export const Hero = () => {
  const [active, setActive] = useState('leader');
  const [hasScrolled, setHasScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setHasScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <section className="relative h-screen w-full flex flex-col justify-end overflow-hidden">
      {/* Cinematic Main Visual */}
      <div className="absolute inset-0 z-0">
        <motion.div
          animate={{ scale: active ? 1.02 : 1 }}
          transition={{ duration: 1.5, ease: "easeOut" }}
          className="w-full h-full"
        >
          <img 
            src={heroImage} 
            alt="The Collective Scene" 
            className="w-full h-full object-cover grayscale-[30%] opacity-70"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0a] via-[#0a0a0a]/20 to-transparent" />
          <div className="absolute inset-0 bg-black/40 mix-blend-multiply" />
        </motion.div>
      </div>

      {/* Editorial Content Overlay */}
      <div className="relative z-20 px-8 pb-20 md:pb-32 max-w-7xl mx-auto w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-end">
          
          {/* Main Title Reveal */}
          <div className="lg:col-span-8">
            <motion.div
              initial={{ opacity: 0, y: 100 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
            >
              <h1 className="text-[12vw] lg:text-[10vw] font-serif italic leading-[0.8] tracking-tighter mb-4 text-white">
                Digital <br />
                <span className="text-white/40">Collective.</span>
              </h1>
            </motion.div>
            
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
              className="flex items-center gap-8 font-mono text-[10px] tracking-[0.6em] text-white/30 uppercase"
            >
              <span>ONE MIND</span>
              <div className="w-12 h-[1px] bg-white/10" />
              <span>THREE SPECIALTIES</span>
              <div className="w-12 h-[1px] bg-white/10" />
              <span>INFINITE SOLUTIONS</span>
            </motion.div>
          </div>

          {/* Interactive Node Selector */}
          <div className="lg:col-span-4 flex flex-col gap-6 items-start lg:items-end">
            <div className="flex gap-4">
              {Object.keys(PERSONAS).map((key) => (
                <button
                  key={key}
                  onClick={() => setActive(key)}
                  className={`relative group p-4 rounded-full border transition-all duration-500 ${active === key ? 'bg-white border-white' : 'bg-transparent border-white/20 hover:border-white/50'}`}
                >
                  <span className={`${active === key ? 'text-black' : 'text-white'}`}>
                    {PERSONAS[key].icon}
                  </span>
                  {active === key && (
                    <motion.div 
                      layoutId="active-ring"
                      className="absolute -inset-2 border border-white rounded-full opacity-50"
                      transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                    />
                  )}
                </button>
              ))}
            </div>

            <AnimatePresence mode="wait">
              <motion.div
                key={active}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="text-left lg:text-right max-w-xs"
              >
                <h3 className="text-2xl font-serif italic text-white mb-2">{PERSONAS[active].serif}</h3>
                <p className="text-xs font-mono tracking-widest text-white/50 uppercase mb-4">{PERSONAS[active].title}</p>
                <p className="text-sm leading-relaxed text-white/70 font-light">
                  {PERSONAS[active].description}
                </p>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </div>

      {/* Scroll Indicator */}
      <motion.div 
        animate={{ 
          opacity: hasScrolled ? 0 : 1,
          y: hasScrolled ? 20 : 0
        }}
        className="absolute bottom-10 left-1/2 -translate-x-1/2 z-30 flex flex-col items-center gap-4 cursor-pointer"
      >
        <span className="text-[10px] font-mono tracking-[0.5em] text-white/20 uppercase">SCROLL</span>
        <div className="w-[1px] h-12 bg-gradient-to-b from-white/20 to-transparent" />
      </motion.div>

      {/* Minimalist Hotspots on Image */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="relative w-full h-full max-w-7xl mx-auto px-8">
          <SubtleHotspot x="22%" y="45%" active={active === 'hacker'} onClick={() => setActive('hacker')} />
          <SubtleHotspot x="50%" y="40%" active={active === 'leader'} onClick={() => setActive('leader')} />
          <SubtleHotspot x="75%" y="45%" active={active === 'ai'} onClick={() => setActive('ai')} />
        </div>
      </div>
    </section>
  );
};

const SubtleHotspot = ({ x, y, active, onClick }) => (
  <div 
    style={{ left: x, top: y }}
    className="absolute -translate-x-1/2 -translate-y-1/2 pointer-events-auto"
  >
    <button 
      onClick={onClick}
      className={`relative w-8 h-8 flex items-center justify-center group`}
    >
      <div className={`w-1 h-1 rounded-full bg-white transition-all duration-500 ${active ? 'scale-[6] opacity-10' : 'scale-100 opacity-40 group-hover:opacity-100'}`} />
      <div className={`absolute inset-0 border border-white/20 rounded-full transition-all duration-500 ${active ? 'scale-150 opacity-100' : 'scale-0 opacity-0 group-hover:scale-100 group-hover:opacity-40'}`} />
    </button>
  </div>
);
