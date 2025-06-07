const Footer = () => {
  const currentYear = new Date().getFullYear();
  
  return (
    <footer className="bg-gray-800 text-white py-6 mt-8">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row justify-between items-center">
          <div className="text-sm">
            © {currentYear} HSQ Forms. Alla rättigheter förbehållna.
          </div>
          
          <div className="mt-4 md:mt-0">
            <ul className="flex space-x-4">
              <li>
                <a href="#" className="text-gray-300 hover:text-white">
                  Sekretesspolicy
                </a>
              </li>
              <li>
                <a href="#" className="text-gray-300 hover:text-white">
                  Användarvillkor
                </a>
              </li>
              <li>
                <a href="#" className="text-gray-300 hover:text-white">
                  Kontakt
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
