<?php
/**
 * This file provides to overwrite the default HumHub / Yii configuration by your local common (Console and Web) environments
 * @see http://www.yiiframework.com/doc-2.0/guide-concept-configurations.html
 * @see http://docs.humhub.org/admin-installation-configuration.html
 * @see http://docs.humhub.org/dev-environment.html
 */
return [
    'components' => [
        'authClientCollection' => [
            'clients' => [
                'itsyouonline' => [
                    'class' => 'humhub\modules\user\authclient\IYO',
                    'clientId' => getenv('CLIENT_ID'),
                    'clientSecret' => getenv('CLIENT_SECRET'),
                ],
            ],
    ],
    
    'urlManager' => [
             'showScriptName' => false,
             'enablePrettyUrl' => true,
         ],
    ]
];
