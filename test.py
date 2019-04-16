from Jumpscale import j
import time
log = j.logger.get('InstallingFreeFolwPages')
# j.logger.loggers_level_set(level='DEBUG')
# usage example
# python3 create_FFP.py -n 10.102.90.219 -j "myjwt" --ztid "83048a0632bd58b2"
# --zttoken "gPDxBv" -sp "dd0b1148-cc9b-47c8-8b26-40ba3f6cffc8" -ssh 2202 -http
# 8082 -mysql 3302 --name freeflowpages_staging
import click

def create_test_container(node,name, jwt, ztid, zttoken, storagepool,http_port,ssh_port,mysql_port):
    myflist = 'https://hub.grid.tf/tf-autobuilder/freeflowpages-freeflow-flist-autostart-master-87ded17368.flist'
    mydir = 'freeflowpages_stag' # change incase staging one
    restic_repo_name='freeflowpages-stag' # make sure DO NOT use _ in naming
    humhubdir = 'ffpData'
    mysqldir =  'mysqlData'
    mysqlbinlogdir = 'mysqlBinLog'
    authkeysdir = 'authKeys'
    backupdir = 'backup'
    sp = storagepool
    data = {'host': node}
    if jwt:
        data['password_'] = jwt
    print ('data conternst is ..... {}.format(data)')
    print (data)
    node_client = j.clients.zos.get('node', data=data)
    nodeip = node_client.public_addr
    url = 'http://{}:6600'.format(nodeip)
    check = node_client.capacity.node_parameters()
    if check[0] not in 'support':
        log.error('Please note node does not in support mode, check if it is developement ... so you can comelete')
    zrobot_cont = node_client.containers.get('zrobot')
    zrobottoken = zrobot_cont.client.bash('zrobot godtoken get').get()
    string = zrobottoken.stdout.split(":")[1]
    token = string.strip()
    j.clients.zrobot.new(node_client.name, data={'url': url, 'god_token_': token})
    node_robot = j.clients.zrobot.robots.get(node_client.name)
    myargs = {'token': zttoken, }
    node_robot.services.find_or_create('github.com/threefoldtech/0-templates/zerotier_client/0.0.1', 'ztclientB',myargs)
    # create directory
    create_humhub = "mkdir -p /mnt/storagepools/%s/%s/%s" % (sp, mydir,humhubdir)
    create_mysql  = "mkdir -p /mnt/storagepools/%s/%s/%s" % (sp, mydir,mysqldir)
    create_mysqlbinlog  = "mkdir -p /mnt/storagepools/%s/%s/%s" % (sp, mydir,mysqlbinlogdir)
    create_auth_keys = "mkdir -p /mnt/storagepools/%s/%s/%s" % (sp, mydir,authkeysdir)
    create_backup = "mkdir -p /mnt/storagepools/%s/%s/%s" % (sp, mydir,backupdir)
    humhub_dir = "/mnt/storagepools/%s/%s/%s" % (sp, mydir,humhubdir)
    mysql_dir  = "/mnt/storagepools/%s/%s/%s/" % (sp, mydir,mysqldir)
    mysqlbinlog_dir  = "/mnt/storagepools/%s/%s/%s/" % (sp, mydir,mysqlbinlogdir)
    authkeys_dir = "/mnt/storagepools/%s/%s/%s" % (sp, mydir,authkeysdir)
    backup_dir = "/mnt/storagepools/%s/%s/%s" % (sp, mydir,backupdir)
    node_client.client.bash(create_humhub).get()
    node_client.client.bash(create_mysql).get()
    node_client.client.bash(create_mysqlbinlog).get()
    node_client.client.bash(create_auth_keys).get()
    node_client.client.bash(create_backup).get()
    container_data = {
        'flist': myflist,
        'mounts': [{'source': humhub_dir, 'target': '/var/www/html/humhub'},
                   {'source': mysql_dir, 'target': '/var/lib/mysql/'},
                   {'source': mysqlbinlog_dir, 'target': '/var/mysql/binlog'},
                   {'source': backup_dir, 'target':'/backup' },
                   {'source': authkeys_dir, 'target': '/root/.ssh/'}],
        'nics': [{'type': 'default'},
                 {'type': 'zerotier', 'name': 'zerotier', 'id': ztid, 'ztClient': 'ztclientB'}],
        'env': [{'name':'CLIENT_ID','value':'freeflowpages'},{'name':'CLIENT_SECRET','value':'dvV2O3zKFkS7ZMDEwOrlhihohdUpzIYs3wut0SCf-23iurWU_cGZ'},
                {'name':'DB_USER','value':'humhub'},{'name':'DB_PASS','value':'Hum_flist_hubB'},{'name':'ROOT_DB_PASS','value':'Hum_flist_root'},
                {'name':'AWS_ACCESS_KEY_ID','value':'5GO9V7YEQSWHF0KMQNYT'},{'name':'AWS_SECRET_ACCESS_KEY','value':'ZfgbqGt61Kp35JmNxVlFzS0eku4AMSAHHQLHgIlC'},
                {'name':'RESTIC_REPOSITORY','value':'s3:https://s3.grid.tf/{0}-backup'.format(restic_repo_name)},{'name':'RESTIC_PASSWORD','value':'86lng11!'},
                {'name':'SMTP_HOST','value':'smtp.sendgrid.net'},{'name':'SMTP_USER','value':'apikey'},{'name':'SMTP_PORT','value':'587'},
                {'name':'SMTP_PASS','value':'SG.BzBNg7kxuSmGqx7Qga3i9Sw.IVhkHdhXQf8FTrIWEl1KQIlKp6mEHJIr_W5mOehBTik'},{'name':'HUMHUB_INSTALLATION_VERSION','value':'1.3.12'}],
        'ports': ['{0}:80'.format(http_port), '{0}:22'.format(ssh_port), '{0}:3306'.format(mysql_port)]}
    humhub_name = name
    container = node_robot.services.create('github.com/threefoldtech/0-templates/container/0.0.1', humhub_name,
                                                   data=container_data)
    log.info('creating humhub container .........')
    container.schedule_action('install').wait(die=True)
    log.info('waiting 5 seconds till container get start then compelete our script .........')
    time.sleep(5)
    freeflowpages_test = node_client.containers.get(humhub_name)
    key = freeflowpages_test.client.bash("cat /root/.ssh/id_rsa.pub").get()
    test_cont_key = key.stdout
    freeflowpages_test.client.bash(
        'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8o0jEGYqe2k7J0TNL6Gg8h86ic3ReiC6THlBnOKPDiKProj/4uMTmi1Qf5OcLIdeHgcP+zy+ZL4kpP7N6VTALRPiTn6Lty6ZP+5mQocaJYosoGLzB6+lx1NW/zXtscv4V3goULiDEx9SBzSuD8wS0k00iHcRjmuFUIfERyYR8mjmWC/sRf1Y7qk9kQjFOLW5Sw0+RLrxr4l2ur/n8bDVgGVpzWypKIsqRU6Rf1HdXWmdAMCucPAkxR5WNies5QFOkyllxI6Fq+G9M0Uf+EubpfpC1oOMWjNFy781M4KZF+FXODcBlwevfvk0HH/5mTHOymIfwVV8vjRzycxjuQib3 pishoy@Bishoy-laptop" >> /root/.ssh/authorized_keys').get()
    contIP = freeflowpages_test.client.zerotier.list()[0]['assignedAddresses'][1]
    container_IP = contIP.split("/")[0]
    return (freeflowpages_test.client , test_cont_key,container_IP)


@click.command()
@click.option('--node', '-n', required=True, help="remote node (ip)")
@click.option('--name', '-name', required=True, help="container name of new FFP contianer")
@click.option('--jwt', '-j', help="optional node jwt")
@click.option('--ztid', '-ztid', required=True, help="zerotier network to join it ")
@click.option('--zttoken', '-zttoken', required=True, help="zerotier token to join it ")
@click.option('--storagepool', '-sp', required=True, help="storage pool that need to be create database/app backup")
@click.option('--http_port', '-http', required=True, help="port that container will use to map 80 port")
@click.option('--ssh_port', '-ssh', required=True, help="port that container will use to map 22 port")
@click.option('--mysql_port', '-mysql', required=True, help="port that container will use to map 3306 port")
def main(node,name, jwt, ztid, zttoken, storagepool, http_port, ssh_port,mysql_port):
    import ipdb; ipdb.set_trace()
    test_client,test_node_key,container_IP = create_test_container(node,name, jwt, ztid, zttoken, storagepool,http_port,ssh_port,mysql_port)
    log.info('now you can access humhub continer by zerotier IP  ssh root@{}'.format(container_IP))


if __name__ == "__main__":
    main()