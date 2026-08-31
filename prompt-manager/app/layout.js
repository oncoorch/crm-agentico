import "./globals.css";

export const metadata = {
  title: "Prompt Manager",
  description: "Editor seguro de system prompts para agentes NICOP",
  icons: {
    icon: "/icon.svg",
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
