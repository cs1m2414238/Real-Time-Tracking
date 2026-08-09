import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Terminal, Shield, Cpu, ArrowRight, Github, Twitter, Linkedin, Menu } from 'lucide-react';
import { Hero } from './components/Hero';

export default function App() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-[#f5f5f5] selection:bg-white selection:text-black antialiased overflow-x-hidden">
      {/* Editorial Navbar */}
      <nav className="fixed top-0 left-0 right-0 z-[100] px-8 py-10 flex justify-between items-center mix-blend-difference">
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-4"
        >
          <span className="text-2xl font-black italic tracking-tighter">TC.</span>
          <div className="h-[1px] w-12 bg-white/30 hidden md:block" />
          <span className="text-[10px] font-mono tracking-[0.4em] uppercase text-white/50 hidden md:block">The Collective Digital</span>
        </motion.div>

        <div className="flex items-center gap-12">
          <div className="hidden md:flex gap-10 text-[11px] font-mono tracking-widest text-white/60">
            <a href="#" className="hover:text-white transition-colors">SELECTED WORKS</a>
            <a href="#" className="hover:text-white transition-colors">THE PROTOCOL</a>
            <a href="#" className="hover:text-white transition-colors">EST. 2026</a>
          </div>
          <button 
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="p-2 hover:bg-white/5 rounded-full transition-colors"
          >
            <Menu className="w-6 h-6" />
          </button>
        </div>
      </nav>

      <main>
        <Hero />
        
        {/* Editorial Section 01 */}
        <section className="py-40 px-8 max-w-7xl mx-auto border-t border-white/5">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12">
            <div className="lg:col-span-4">
              <span className="text-[10px] font-mono tracking-[0.5em] text-white/40 uppercase mb-8 block">/ 01. Concept</span>
              <h2 className="text-5xl md:text-7xl font-serif italic font-light leading-tight">
                The <br />
                <span className="text-white/40">Symmetry</span> <br />
                of Three.
              </h2>
            </div>
            <div className="lg:col-span-7 lg:col-start-6 flex flex-col justify-end">
              <p className="text-2xl md:text-3xl font-light leading-relaxed text-white/80 mb-12">
                We operate at the intersection of extreme technical proficiency and refined aesthetic sensibilities. Three distinct specializations, one unified output.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pt-12 border-t border-white/10">
                <Stat label="Uptime" value="99.9%" />
                <Stat label="Secured" value="$2B+" />
                <Stat label="Nodes" value="Classified" />
              </div>
            </div>
          </div>
        </section>

        {/* Work Grid Pre-reveal */}
        <section className="py-20 px-8">
          <div className="aspect-[21/9] w-full bg-white/5 rounded-[40px] overflow-hidden relative group cursor-pointer">
            <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent z-10" />
            <img 
              src="https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop" 
              alt="Network" 
              className="w-full h-full object-cover grayscale group-hover:scale-105 group-hover:grayscale-0 transition-all duration-1000"
            />
            <div className="absolute bottom-12 left-12 z-20">
              <h3 className="text-4xl md:text-6xl font-serif italic mb-4">View All Nodes</h3>
              <div className="flex items-center gap-4 text-white/60 font-mono text-xs tracking-widest">
                <span>OPEN SYSTEM</span>
                <ArrowRight className="w-4 h-4" />
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="py-20 px-8 border-t border-white/5 mt-20">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-end gap-12">
          <div className="max-w-xl">
            <h2 className="text-6xl md:text-8xl font-serif italic mb-8">Let's talk.</h2>
            <p className="text-xl text-white/40 mb-12 font-mono tracking-tighter">init@thecollective.digital</p>
          </div>
          <div className="flex gap-12 text-xs font-mono tracking-widest text-white/40">
            <a href="#" className="hover:text-white transition-colors">TWITTER</a>
            <a href="#" className="hover:text-white transition-colors">GITHUB</a>
            <a href="#" className="hover:text-white transition-colors">LINKEDIN</a>
          </div>
        </div>
        <div className="max-w-7xl mx-auto mt-20 pt-8 border-t border-white/5 flex justify-between items-center text-[10px] font-mono text-white/20 tracking-widest">
          <span>THE COLLECTIVE — 2026 COPYRIGHT</span>
          <span>BUILT BY THE TRINITY</span>
        </div>
      </footer>

      {/* Fullscreen Overlay Menu */}
      <AnimatePresence>
        {isMenuOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[200] bg-[#0a0a0a] flex flex-col items-center justify-center p-8"
          >
            <button 
              onClick={() => setIsMenuOpen(false)}
              className="absolute top-12 right-12 text-white/40 hover:text-white font-mono text-xs tracking-[0.5em]"
            >
              CLOSE
            </button>
            <nav className="flex flex-col items-center gap-8">
              {['EXPERIENCE', 'PROTOCOLS', 'ARCHIVE', 'CONTACT'].map((item, i) => (
                <motion.a
                  key={item}
                  initial={{ y: 50, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: i * 0.1 }}
                  href="#"
                  className="text-6xl md:text-8xl font-serif italic hover:text-white/40 transition-colors"
                >
                  {item}
                </motion.a>
              ))}
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

const Stat = ({ label, value }) => (
  <div className="flex flex-col gap-2">
    <span className="text-[10px] font-mono tracking-widest text-white/30 uppercase">{label}</span>
    <span className="text-3xl font-serif italic">{value}</span>
  </div>
);
