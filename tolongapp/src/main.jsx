import { useEffect, useMemo, useRef, useState } from 'react'
import { createRoot } from 'react-dom/client'
import {
  ArrowRight, Bell, Check, ChevronRight, CircleHelp, Compass, Droplets,
  Flashlight, HeartPulse, Home, Info, MapPin, Package, Radio, ShieldCheck,
  Siren, Sparkles, Users, Volume2, VolumeX, Waves, Wind, X
} from 'lucide-react'
import './styles.css'

const contexts = {
  home: {
    eyebrow: 'SAFE AT HOME', title: 'Good morning, Mia.',
    sub: 'Your household is ready for today.', mood: 'Welcome', accent: 'sage',
    note: 'You have 3 small actions left this week.',
  },
  alert: {
    eyebrow: 'ACTIVE ALERT', title: 'Stay calm, stay informed.',
    sub: 'A flood advisory is active near your area.', mood: 'Focused', accent: 'terracotta',
    note: 'Move valuables up and keep your go-bag close.',
  },
  guide: {
    eyebrow: 'PREPAREDNESS GUIDE', title: 'Small steps make a big difference.',
    sub: 'Build confidence one checklist at a time.', mood: 'Helpful', accent: 'amber',
    note: 'Today’s guide: prepare 3 days of water.',
  },
  map: {
    eyebrow: 'EVACUATION ROUTE', title: 'A safer route is ready.',
    sub: 'Your nearest accessible center is 1.2 km away.', mood: 'Determined', accent: 'blue',
    note: 'Walk via Mabini St. — it avoids the low bridge.',
  },
}

function Logo() {
  return <div className="brand"><span className="brand-mark"><span /><span /><span /><span /></span><span>Tolong<span className="brand-dot">.</span></span></div>
}

function Character({ context }) {
  const isAlert = context === 'alert'
  const isGuide = context === 'guide'
  const isMap = context === 'map'
  return <div className={`character-wrap ${context}`} aria-label={`${contexts[context].mood} character illustration`}>
    <div className="sun-orb" />
    <svg className="character" viewBox="0 0 260 210" role="img">
      <path d="M43 187c23-24 49-36 82-36 45 0 81 14 99 36" fill="none" stroke="#c9d8c7" strokeWidth="4" strokeLinecap="round" />
      <path d="M82 119c-6-28 7-68 48-70 39-2 57 27 53 64-2 26-14 42-49 43-32 1-47-13-52-37Z" fill="#a3c4a5" />
      <path d="M82 79c8-40 65-49 92-10-15-4-27-12-39-14-15 14-31 21-53 24Z" fill="#3f5d51" />
      <path d="M93 101c0-18 14-32 37-32 23 0 37 14 37 32v27c0 15-17 28-37 28-20 0-37-13-37-28v-27Z" fill="#f7e9cf" />
      <path d={isAlert ? 'M108 104l7 2' : 'M108 105c4 4 8 4 12 0'} fill="none" stroke="#3f5d51" strokeWidth="3.5" strokeLinecap="round" />
      <path d={isAlert ? 'M137 106l7-2' : 'M137 105c4 4 8 4 12 0'} fill="none" stroke="#3f5d51" strokeWidth="3.5" strokeLinecap="round" />
      <circle cx="116" cy="116" r="3.3" fill="#3f5d51" /><circle cx="147" cy="116" r="3.3" fill="#3f5d51" />
      <path d={isAlert ? 'M124 132c7-5 14-5 21 0' : 'M123 130c7 9 16 9 24 0'} fill="none" stroke="#bd7357" strokeWidth="3.5" strokeLinecap="round" />
      <path d="M94 151c14 9 33 13 50 9 10-3 20-7 28-15l16 43H78l16-37Z" fill={isAlert ? '#c96c56' : '#719b7b'} />
      <path d="M108 188l-6-31m49 31 4-36" stroke="#3f5d51" strokeWidth="7" strokeLinecap="round" />
      {context === 'home' && <path d="M83 161c-15 1-27-8-28-23-1-8 3-12 9-9l15 14 4-15c2-8 8-8 10-1l-1 23c-1 6-3 9-9 11Z" fill="#a3c4a5" />}
      {isAlert && <><path d="M169 156l19-28c3-5 10-3 9 3l-8 36-10 4Z" fill="#a3c4a5" /><path d="M179 132l12-11" stroke="#3f5d51" strokeWidth="4" strokeLinecap="round" /><path d="M185 114c6-4 13-4 18 0" fill="none" stroke="#d18b4b" strokeWidth="5" strokeLinecap="round" /></>}
      {isGuide && <><rect x="161" y="142" width="35" height="28" rx="5" fill="#e4ae60" transform="rotate(-8 161 142)" /><path d="M169 151h20m-20 7h14" stroke="#fff6df" strokeWidth="3" strokeLinecap="round" /><path d="M170 140l12-10" stroke="#3f5d51" strokeWidth="4" strokeLinecap="round" /></>}
      {isMap && <><path d="M164 142l38-12 2 37-38 12-2-37Z" fill="#f6e4bc" stroke="#3f5d51" strokeWidth="3" /><path d="m174 150 17 4 7-11m-18 27 12-13" fill="none" stroke="#719b7b" strokeWidth="3" /><circle cx="192" cy="154" r="4" fill="#c96c56" /><path d="M176 138 182 129" stroke="#3f5d51" strokeWidth="4" strokeLinecap="round" /></>}
    </svg>
    <div className="character-ground" />
    <span className="mood-chip"><Sparkles size={13} /> {contexts[context].mood}</span>
  </div>
}

function StatusCard({ onAlert }) {
  return <section className="status-card">
    <div className="status-top"><span className="eyebrow">HOUSEHOLD STATUS</span><span className="offline-pill"><span className="status-dot" /> Offline ready</span></div>
    <div className="status-main"><div><h2>Ready for rain.</h2><p>All essential supplies are covered for <strong>2 days.</strong></p></div><div className="score-ring"><span>78</span><small>%</small></div></div>
    <div className="progress"><span style={{ width: '78%' }} /></div>
    <button className="text-button" onClick={onAlert}>View household readiness <ArrowRight size={16} /></button>
  </section>
}

function FloodAlertSound() {
  const [playing, setPlaying] = useState(false)
  const audioRef = useRef(null)
  const timerRef = useRef(null)

  const playTone = (context, destination, startTime, frequency, duration) => {
    const oscillator = context.createOscillator()
    const gain = context.createGain()
    oscillator.type = 'triangle'
    oscillator.frequency.setValueAtTime(frequency, startTime)
    gain.gain.setValueAtTime(0.0001, startTime)
    gain.gain.exponentialRampToValueAtTime(0.12, startTime + 0.025)
    gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration)
    oscillator.connect(gain).connect(destination)
    oscillator.start(startTime)
    oscillator.stop(startTime + duration + 0.03)
  }

  const start = () => {
    const AudioContext = window.AudioContext || window.webkitAudioContext
    if (!AudioContext) return
    const audio = audioRef.current || new AudioContext()
    audioRef.current = audio
    if (audio.state === 'suspended') audio.resume()
    const playCycle = () => {
      const now = audio.currentTime
      playTone(audio, audio.destination, now, 520, 0.28)
      playTone(audio, audio.destination, now + 0.34, 660, 0.28)
    }
    playCycle()
    timerRef.current = window.setInterval(playCycle, 1800)
    setPlaying(true)
  }

  const stop = () => {
    window.clearInterval(timerRef.current)
    timerRef.current = null
    setPlaying(false)
  }

  useEffect(() => () => {
    window.clearInterval(timerRef.current)
    if (audioRef.current) audioRef.current.close()
  }, [])

  return <button className={`sound-toggle ${playing ? 'playing' : ''}`} onClick={playing ? stop : start} aria-pressed={playing}>
    <span className="sound-toggle-icon">{playing ? <Volume2 size={15} /> : <VolumeX size={15} />}</span>
    <span>{playing ? 'Warning sound playing' : 'Play warning sound'}</span>
    {playing && <span className="sound-bars"><i /><i /><i /></span>}
  </button>
}

function AlertCard({ onDismiss, onMap }) {
  return <section className="alert-card"><div className="alert-icon"><Waves size={22} /></div><div className="alert-copy"><div className="alert-title"><span>FLOOD ADVISORY</span><span className="alert-time">8 min ago</span></div><h3>Rising water reported near Marikina River.</h3><p>Keep your go-bag close. Avoid low-lying roads and monitor local updates.</p><FloodAlertSound /><div className="alert-actions"><button onClick={onMap}>Open safer route <ChevronRight size={16} /></button><button className="icon-button" aria-label="Dismiss alert" onClick={onDismiss}><X size={16} /></button></div></div></section>
}

function QuickAction({ icon, label, meta, onClick, tone = '' }) { return <button className={`quick-action ${tone}`} onClick={onClick}><span className="quick-icon">{icon}</span><span><b>{label}</b><small>{meta}</small></span><ChevronRight size={18} className="quick-arrow" /></button> }

function HomeView({ setContext, alertVisible, setAlertVisible }) {
  return <>
    <div className="hero"><div className="hero-copy"><span className="eyebrow">{contexts.home.eyebrow}</span><h1>{contexts.home.title}</h1><p>{contexts.home.sub}</p><div className="hero-note"><Check size={14} /> {contexts.home.note}</div></div><Character context="home" /></div>
    {alertVisible && <AlertCard onDismiss={() => setAlertVisible(false)} onMap={() => setContext('map')} />}
    <StatusCard onAlert={() => setContext('guide')} />
    <div className="section-heading"><div><span className="eyebrow">YOUR NEXT STEPS</span><h2>Keep it simple.</h2></div><button className="help-button"><CircleHelp size={19} /></button></div>
    <div className="quick-grid"><QuickAction icon={<Package size={19} />} label="Go-bag checklist" meta="3 items to add" onClick={() => setContext('guide')} tone="green" /><QuickAction icon={<Compass size={19} />} label="Safe places" meta="2 centers nearby" onClick={() => setContext('map')} tone="blue" /><QuickAction icon={<Droplets size={19} />} label="Water coverage" meta="Good for 2 days" onClick={() => setContext('guide')} tone="amber" /><QuickAction icon={<Users size={19} />} label="Household" meta="4 people · 1 pet" onClick={() => setContext('guide')} tone="rose" /></div>
    <div className="micro-note"><Info size={14} /> Last synced locally · 30 Sep 2026, 5:42 AM</div>
  </>
}

function GuideView({ setContext }) {
  const items = ['Drinking water · 8 L', 'Ready-to-eat food · 6 packs', 'First aid supplies', 'Power bank + flashlight']
  return <><div className="context-hero"><div><span className="eyebrow">{contexts.guide.eyebrow}</span><h1>{contexts.guide.title}</h1><p>{contexts.guide.sub}</p></div><Character context="guide" /></div><section className="guide-card"><div className="guide-header"><div className="guide-icon"><Flashlight size={21} /></div><div><span className="eyebrow">TODAY'S MINI GUIDE</span><h2>Make your kit easy to grab</h2></div></div><p className="guide-intro">Keep essentials together in one waterproof bag. Start with what your household needs most.</p><div className="checklist">{items.map((item, i) => <div className="check-row" key={item}><span className={`check ${i < 2 ? 'done' : ''}`}>{i < 2 && <Check size={13} />}</span><span>{item}</span>{i === 2 && <small>Next</small>}</div>)}</div><button className="primary-button" onClick={() => setContext('home')}>Save progress <Check size={17} /></button></section></>
}

function MapView() {
  return <><div className="context-hero map-hero"><div><span className="eyebrow">{contexts.map.eyebrow}</span><h1>{contexts.map.title}</h1><p>{contexts.map.sub}</p></div><Character context="map" /></div><section className="map-card"><div className="map-canvas"><div className="map-grid" /><div className="route route-one" /><div className="route route-two" /><div className="map-pin home-pin"><Home size={15} /></div><div className="map-pin shelter-pin"><ShieldCheck size={17} /></div><div className="map-label label-home">You</div><div className="map-label label-shelter">San Roque Center</div><div className="map-distance">1.2 km · 18 min walk</div></div><div className="route-info"><div className="route-icon"><MapPin size={19} /></div><div><span className="eyebrow">RECOMMENDED CENTER</span><h2>San Roque Covered Court</h2><p>Wheelchair access · Pet friendly · First aid</p></div></div><button className="primary-button">Start navigation <ArrowRight size={17} /></button></section></>
}

function App() {
  const [view, setView] = useState('home');
  const [context, setContext] = useState('home');
  const [alertVisible, setAlertVisible] = useState(true);
  const activeTitle = useMemo(() => view === 'home' ? 'Home' : view === 'guide' ? 'Prepare' : 'Safe places', [view]);
  const handleContext = (next) => { setContext(next); if (next === 'map' || next === 'guide' || next === 'home') setView(next) }
  const navigate = (next) => { setView(next); setContext(next === 'guide' ? 'guide' : next === 'map' ? 'map' : 'home') }
  return <div className="app-shell"><header className="app-header"><Logo /><div className="header-actions"><button className="header-icon"><Radio size={18} /></button><button className="header-icon"><Bell size={18} /><span className="notification-dot" /></button><div className="avatar">M</div></div></header><main><div className="view-label"><span>{activeTitle}</span><span className="date-label">Tuesday · Sep 30</span></div>{view === 'home' && <HomeView setContext={handleContext} alertVisible={alertVisible} setAlertVisible={setAlertVisible} />}{view === 'guide' && <GuideView setContext={handleContext} />}{view === 'map' && <MapView />}</main><nav className="bottom-nav"><button className={view === 'home' ? 'active' : ''} onClick={() => navigate('home')}><Home size={21} /><span>Home</span></button><button className={view === 'guide' ? 'active' : ''} onClick={() => navigate('guide')}><Package size={21} /><span>Prepare</span></button><button className={view === 'map' ? 'active' : ''} onClick={() => navigate('map')}><Compass size={21} /><span>Safe places</span></button><button onClick={() => setContext('alert')}><HeartPulse size={21} /><span>Help</span></button></nav></div>
}

export default App

createRoot(document.getElementById('root')).render(<App />)
