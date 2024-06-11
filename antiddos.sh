if [ $# -eq 2 ] || [ $# -eq 3 ]; then
MaxCountHTTPBOT='60'
if [ $3 > 0 ]
then
MaxCountHHTPUSER=$3
else
MaxCountHHTPUSER=45
fi
echo "param: $3"
echo "ban: $MaxCountHHTPUSER"

DATE=`LC_TIME=en_US.UTF-8 date -d "-1 min" +"%d/%b/%Y:%H:%M"`
LOG='/var/www/'$1'/data/logs/'$2'.access.log' #Логи к конкретному сайту
LOGNGINX='/var/log/nginx/access.log' #Логи nginx
DIRECTORY_LOG='/var/local/super/tmp' #Директория куда пишим логи
DIRECTORY_BAN='/var/local/super/ban' #Директория куда пишим бликировки
format='.js|.css|.png|.gif|.jpg|.jpeg|.ico|.svg|.webp|.woff|.woff2|.xml|.ttf|.eot|.pdf|.mp3|.avi|.flv|.csv|.rar|.zip|.txt|.rtf|.odt|.doc|.docx|.xls$'


grep $DATE $LOG | grep -Pv $format > $DIRECTORY_LOG/$2-nginx_acc.list

grep 'HTTP/1.0' $DIRECTORY_LOG/$2-nginx_acc.list > $DIRECTORY_LOG/http-1-0-$2.list
grep 'HTTP/2.0' $DIRECTORY_LOG/$2-nginx_acc.list  > $DIRECTORY_LOG/http-2-0-$2.list
grep 'HTTP/1.1' $DIRECTORY_LOG/$2-nginx_acc.list  > $DIRECTORY_LOG/http-1-1-$2.list

awk '{ print $1 }' $DIRECTORY_LOG/$2-nginx_acc.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/$2-nginx_acc_ban.list
awk '{ print $1 }' $DIRECTORY_LOG/http-1-0-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/$2-nginx_acc-1-0_ban.list
awk '{ print $1 }' $DIRECTORY_LOG/http-1-1-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/$2-nginx_acc-1-1_ban.list
awk '{ print $1 }' $DIRECTORY_LOG/http-2-0-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/$2-nginx_acc-2-0_ban.list

awk '{ print $1 }' $DIRECTORY_LOG/http-1-0-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/ip-http-1-0-$2.list
awk '{ print $1 }' $DIRECTORY_LOG/http-2-0-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/ip-http-2-0-$2.list
awk '{ print $1 }' $DIRECTORY_LOG/http-1-1-$2.list | sort | uniq -c | sort -nr | awk '{print $1 "-" $2}' > $DIRECTORY_LOG/ip-http-1-1-$2.list

countHttp10=`cat $DIRECTORY_LOG/http-1-0-$2.list |wc -l`
countHttp20=`cat $DIRECTORY_LOG/http-2-0-$2.list |wc -l`
countHttp11=`cat $DIRECTORY_LOG/http-1-1-$2.list |wc -l`

if [ ! -f $DIRECTORY_BAN/ban_all_ip.list ]; then
echo '' > $DIRECTORY_BAN/ban_all_ip.list
fi
if [ ! -f $DIRECTORY_BAN/ban_ip-$2.list ]; then
echo '' > $DIRECTORY_BAN/ban_ip-$2.list
fi
#=============== FUNCTION BLOCK ===============

blockIp() {
    if [ $2 -ge 30 ]; then
      echo "$1 ban3 ip: $3 | COUNTBANREF: $2"
	  if [[ $3 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ipset -A ban3 $3
	  else 
		ipset -A ban63 $3
	  fi
      return 3
    fi
    if [ $2 -ge 5 ]; then
      echo "$1 ban2 ip: $3 | COUNTBANREF: $2"
	  if [[ $3 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ipset -A ban2 $3
	  else 
		ipset -A ban62 $3
	  fi
      return 2
    fi
    if [ $2 -ge 2 ]; then
      echo "$1 ban1 ip: $3 | COUNTBANREF: $2"
	  if [[ $3 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ipset -A ban1 $3
	  else 
		ipset -A ban61 $3
	  fi
      return 1
    fi

    echo "$1 ban ip: $3 | COUNTBANREF: $2"
	if [[ $3 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ipset -A ban $3
	else 
		ipset -A ban6 $3
	fi
    return 0
}

#================== HTTP 1.0 ==================
if [ $countHttp10 -ge $countHttp11 -o $countHttp10 -ge 100 ]; then

for i in `cat $DIRECTORY_LOG/$2-nginx_acc-1-0_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $(($MaxCountHTTPBOT / 2)) ]; then
    echo $addr >> $DIRECTORY_BAN/ban_ip-1-0-$2.list
    echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
    #Если попался N раз
    COUNTBANREF=`grep -o $ipHttp $DIRECTORY_BAN/ban_ip-1-0-$2.list | wc -w`
	blockIp "HTTP 1.0" $COUNTBANREF $addr
    continue
  fi
done

fi

#================ HTTP 1.1 ===================
for i in `cat $DIRECTORY_LOG/$2-nginx_acc-1-1_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $MaxCountHTTPBOT ]; then
    echo $addr >> $DIRECTORY_BAN/ban_ip-1-1-$2.list
    echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
    #Если попался N раз
    COUNTBANREF=`grep -o $ipHttp $DIRECTORY_BAN/ban_ip-1-1-$2.list | wc -w`
	blockIp "HTTP 1.1" $COUNTBANREF $addr
    continue
  fi
done

#================ HTTP 2.0 ===================
for i in `cat $DIRECTORY_LOG/$2-nginx_acc-2-0_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $MaxCountHTTPBOT ]; then
    echo $addr >> $DIRECTORY_BAN/ban_ip-2-0-$2.list
    echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
    #Если попался N раз
    COUNTBANREF=`grep -o $ipHttp $DIRECTORY_BAN/ban_ip-2-0-$2.list | wc -w`
	blockIp "HTTP 2.0" $COUNTBANREF $addr
    continue
  fi
done

#=======================HTTP 200 INPUT ==========================

for i in `cat $DIRECTORY_LOG/$2-nginx_acc_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $(($MaxCountHTTPBOT * 4 )) ]; then
  echo $addr >> $DIRECTORY_BAN/ban_ip-$2.list
  echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
  ipset -A ban3 $addr
  echo "HTTP ALL ban3 ip: $addr | FULL COUNT: $count"
  continue
  fi
done

#=======================HTTP 100 INTUP==========================

for i in `cat $DIRECTORY_LOG/$2-nginx_acc_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $(($MaxCountHTTPBOT * 3 )) ]; then
  echo $addr >> $DIRECTORY_BAN/ban_ip-$2.list
  echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
  ipset -A ban2 $addr
  echo "HTTP ALL ban2 ip: $addr | FULL COUNT: $count"
  continue
  fi
done

#=======================HTTP MaxCountHHTPUSER==========================
for i in `cat $DIRECTORY_LOG/$2-nginx_acc_ban.list`
do
  addr=`echo $i | awk -F- '{print $2}'`
  count=`echo $i | awk -F- '{print $1}'`
  if [ $count -ge $(($MaxCountHTTPBOT * 2 )) ]; then
  echo $addr >> $DIRECTORY_BAN/ban_ip-$2.list
  echo $addr >> $DIRECTORY_BAN/ban_all_ip.list
  ipset -A ban $addr
  echo "HTTP ALL ban1 ip: $addr | FULL COUNT: $count"
  continue
  fi
done

fi
