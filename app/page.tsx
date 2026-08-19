const features = [
  ["Client memory", "Every customer gets a private history with services, preferences, notes and appointment photos."],
  ["Fast booking", "Let customers book from the web, Telegram or the future mobile app without friction."],
  ["Smart reminders", "Confirmation, 24-hour, 1-hour and 10-minute reminders are handled automatically."],
  ["Barber workflow", "See today's calendar, open a customer card, repeat the last service and finish an appointment in seconds."],
  ["AI assistant", "Turn natural-language notes into structured preferences and help customers book through Telegram."],
  ["Business control", "Owners get staff, services, schedules and performance analytics in one place."],
];

export default function Home() {
  return (
    <main className="page">
      <nav className="nav">
        <div className="brand">BarberOS</div>
        <div><a href="#features">Features</a><a href="#vision">Vision</a></div>
      </nav>

      <section className="hero" id="vision">
        <div className="eyebrow">The operating system for modern barbershops</div>
        <h1>Never forget a customer.</h1>
        <p>
          Booking, customer memory, barber CRM, Telegram automation and smart reminders —
          designed around the way a real barbershop works.
        </p>
        <div className="actions">
          <a className="btn primary" href="#features">Explore the product</a>
          <a className="btn" href="https://github.com/topuniuz/barber">View on GitHub</a>
        </div>
      </section>

      <section className="grid" id="features">
        {features.map(([title, description]) => (
          <article className="card" key={title}>
            <h2>{title}</h2>
            <p>{description}</p>
          </article>
        ))}
      </section>

      <footer className="footer">BarberOS · Built for a fast, personal barber experience.</footer>
    </main>
  );
}
