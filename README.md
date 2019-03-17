### creating humhub container :-
 - first you need to connect to 0-robot
 ```
 robot = j.clients.zrobot.robots['local']
```
- creating the container with the latest flist :-
  - FreeFlow flist available [here](https://hub.grid.tf/tf-autobuilder) , last flist is [link](https://hub.grid.tf/tf-autobuilder/freeflowpages-freeflow-server-autostart-master-c8ffa7381c.flist)
  - container_data of freeflow that mentioned below from [here](https://docs.grid.tf/threefold/itenv_threefold_main/src/branch/master/freeflowpages/create_FFP_masster.py)
 ```
    container = robot.services.create('github.com/threefoldtech/0-templates/container/0.0.1', 'zerodbcontainer', data=container_data)
    container.schedule_action('install')
    container.schedule_action('start')
    container.schedule_action('stop')
```
Don't forget to Install [IYO module](https://github.com/freeflowpages/freeflow-iyo-module)

#### for more info on how to create container [check here](https://github.com/threefoldtech/0-templates/tree/development/templates/container)
### Flist Creation

- to edit the flist :- 
  - you can edit the flist.sh file and the autobuilder will build the flist with the new changes [flist.sh](https://github.com/freeflowpages/freeflow-server/blob/master/utils/flist.sh)
  
  For more info on how to complete installing humhub please check [Here]()
  
- then from browser http://container_zerotier_IPAddress/humhub/
  - Follow instructions as Follow
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-01.jpg)
  - second image you see humhub checks for some configuration if all okay hit next
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-02.jpg)
  - for Database Configuration :- 
     - Hostname : localhost
     - Username : {db_username}
     - Password : {db_password}
     - DataBase Name : humhub
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-03.jpg)
  - Choose a name for the new social network
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-04.jpg)
  - Create a new Admin account for humhub which will have administrator privileges
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-05.jpg)
  - now you can sign in with IYO 
![](https://github.com/threefoldgrid/freeflow/blob/master/humhub-06.jpg)

