# Prime Estate — basic backend setup

The website is now a PHP-hosted site with a lightweight enquiry backend.

## Files

- `index.php` — hosting entry point; includes the main `real-estate.html` page.
- `real-estate.html` — design/content source.
- `submit.php` — validates enquiries and saves them to `data/inquiries.csv`.
- `data/.htaccess` — blocks direct web access to saved enquiries on Apache hosting.
- `real-estate.before-backend.html` — backup of the original page.

## Test locally

From this folder, run:

```bash
php -S localhost:8000
```

Then open `http://localhost:8000/` and submit the callback form. The first successful submission creates `data/inquiries.csv`.

## Upload

Upload `index.php`, `real-estate.html`, `submit.php`, `data/.htaccess`, and the rest of the folder to a PHP-enabled host. Make sure PHP can write to the `data` directory. Do not expose `data/inquiries.csv` publicly.

The endpoint stores leads locally; it does not send email yet. A real mailbox can be added later through the hosting provider's SMTP or mail service without changing the front-end flow.
