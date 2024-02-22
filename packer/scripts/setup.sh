sudo apt-get update
sudo apt-get install nginx
#sudo nano /etc/nginx/sites-available/vonMerkatz
#server {
#    listen 80;
#    server_name mywebsite.com www.mywebsite.com;
#    root /var/www/mywebsite/html;
#    index index.html index.htm;
#
#    location / {
#        try_files $uri $uri/ =404;
#    }
#}
sudo ln -s /etc/nginx/sites-available/mywebsite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo mkdir -p /var/www/mywebsite/html
sudo cp -r path/to/your/website/* /var/www/mywebsite/html/
sudo chown -R www-data:www-data /var/www/mywebsite

