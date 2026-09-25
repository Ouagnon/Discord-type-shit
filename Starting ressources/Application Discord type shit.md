# Application Discord type shit :



## Architecture de l'application :



L'application est séparé en plusieurs segment : 



Un serveur : Plusieurs salon textuel et vocaux, tous les utilisateurs sont par défaut dans ce serveur.

Un coin personnel : Liste de messages privés et de groupes privées, je peux ajouter des chats privés et des groupes privés avec les utilisateurs que j'ai ajouté en amis.
Un coin paramètre : Réglage classique, adresse mail, mdp, notification etc...

Coin personnalisation de profil : Pseudo, icone de profile, bannière de profil, status, status personnalisé, fond de profil etc...



L'application possède aussi un panneau administrateur permettant en se connectant à un BO sur le serveur d'administrer l'application, l'administrateur peut :



Gérer les utilisateur (supprimer profil)

Gérer le serveur principal dans lequel tous les users sont par défaut

Gérer les différents serveurs et ses salons

Gérer les données enregistrés (effecer des messages plus vieux qu'une date, effacer des soundboard enregistré, des emoji enregistré etc...)

Mettre l'application en maintenance

etc...



## User story :

### Persona : Utilisateur lambda



US1 : En tant qu'utilisateur je veux pouvoir créer mon compte avec une adresse mail et un mot de passe. Après quoi on me demande un pseudo et si je le souhaite une image de profil.



US2 : En tant qu'utilisateur, une fois que j'ai un compte, je souhaite pouvoir me connecter à l'aide de mon adresse mail et mon mot de passe. Si je l'ai activé à la création du compte ou ultérieurement, au moment de la connexion on me demande mon code A2F



US3 : En tant qu'utilisateur connecté, quand je lance l'application j'arrive sur la liste de mes message et groupes privés. J'ai accès à une zone en haut pour changer entre message et groupe privés, le serveur général, la personnalisation, les paramètre de l'application. Je repère où je suis grâce à une barre blanche sous l'icone de là où je suis.



US4 : En tant qu'utilisateur connecté, je peux accéder aux paramètre de l'application, depuis cette page je peux gérer : mon adresse mail, mon mot de passe, activer l'a2f, gérer les paramètres de notification, gérer mon compte (déconnection/changer de compte/supprimer le compte). 



US5 : En tant qu'utilisateur connecté, je peux accéder à la personnalisation, depuis cet affichage j'ai deux sous affichage, la personnalisation du profil, la personnalisation de l'application et la personnalisation d'émoji et soundboard



US6 : En tant qu'utilisateur connecté dans la personnalisation je peux personnaliser mon profil : Modifier le pseudo, modifier l'icone de profil, modifier la bannière de profil, modifier le fond de profil, modifier la police d'écriture de mon pseudo, modifier mon status (En ligne, inactif, ne pas déranger, invisible), modifier mon status personnalisé, (un cours text affiché sur mon profil). Je peux aussi copier mon tag utilisateur.



US6 : En tant qu'utilisateur connecté dans la personnalisation je peux personnaliser l'application, je peux définir un niveau de zoom, une taille de police, je peux défini une couleur de fond/un dégradé de deux couleurs et autre paramètre classique



US7 : En tant qu'utilisateur connecté dans la personnalisation je peux créer et voir mes émojis personnalisés et mes soundboards, je peux ajouter un nouvel émoji perso eet une nouvelle soundboard perso, je peux supprimer les émojis et soundboard que j'ai créé (les supprime aussi pour les gens à qui je les ais partagé). Je peux retirer de ma liste les emoji et soundboard qu'on m'a partagé



US8 : En tant qu'utilisateur connecté dans la liste des messages et groupes privés ou dans les salons du serveur général, j'ai en bas de mon écran un petit cadre rectangulaire avec mon icone de profil avec en petit en bas à gauche de cette dernière un petit rond avec mon status, mon pseudo avec en dessous en petit mon status personnalisé et au bout un bouton ami permettant d'accéder à ma liste d'ami. Si j'appui sur mon icone, je peux modifier mon status, si j'appuis sur mon status personnalisé je peux le modifier.



US9 : US8 : En tant qu'utilisateur connecté dans la liste d'ami, je peux voir mes amis rangé dans l'ordre alphabétique, je peux chercher un ami via son pseudo, chaque ami dans la liste a à sa droite deux bouton "Envoyer un mp" et "Retirer l'ami", retirer l'ami ouvre une fenetre contextuelle demandant deux fois si on est sûr. En au de cet affichage on a un bouton 'ajouter un ami' permettant d'envoyer une demande d'ami à l'aide de son tag.



US10 : En tant qu'utilisateur connecté depuis l'affichage des messages et groupes privé je peux voir mes messages et groupes privé existant, j'ai un bouton pour rechercher des mp et groupes privés, j'ai aussi un bouton en haut pour commencer un message privé avec un ami avec qui je n'en ai pas encore ou alors commencer un groupe privé en choisissant plusieurs utilisateurs, un nom de groupe et une icone (facultatif)



US11 : En tant qu'utilisateur connecté, j'ai accès au différents salon textuel et chat vocal du serveur général de l'application.



US12 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, je peux voir les ancien message, seulement les 30 dernier sont affiché, si je scroll vers le haut les 30 encore plus précédents sont chargé et ainsi de suite



US13 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, je peux écrire un message, je peux ajouter du markdown dans mon message et y ajouter jusqu'à 10 fichier/intégrations chacun de max 50Mo



US14 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, je peux ajouter un émoji en réaction au message d'un autre utilisateur



US15 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, je peux copier un message et son markdown



US16 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, je peux faire l'action "répondre au message", ce après quoi mon prochain message aura au dessus de ce dernier un petit cardre montrant le message auquel on répond et si trop long un extrait de ce dernier, si on appui sur le cadre on remontre au message concerné qui est 'highlight'



US17 : En tant qu'utilisateur connecté dans un salon textuel, messages ou groupe privé, à l'aide d'un bouton à droite de la zone d'écriture je peux sélectionner un emoji ou soundboard à partager, cela envoie un message qui est juste un cadre avec l'emoji/l'audio écoutable de la soundboard, son nom et en dessous un bouton 'ajouter' ce qui ajoute l'emoji ou la soundboard à la bibliothèque de l'utilisateur qui appui sur le bouton

US18 : En tant qu'utilisateur dans des messages privés ou dans un groupe privés, je peux lancer un appel vocal avec l'utilisateur du mp ou du groupe privé



US19 : En tant qu'utilisateur connecté dans le serveur général je peux voir sous un chat vocal les utilisateur qui y sont actuellement connectés (icone et pseudo)



US20 : En tant qu'utilisateur connecté dans le serveur général je peux me connecter dans un salon vocal afin de discuter avec les autres utilisateurs à l'intérieurs de ce dernier à l'aide de mon micro



US21 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux choisir mes périphérique d'entrés et de sortie



US22 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux désactiver mon micro ou le son ou les deux.



US23 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux déclencher une soundboard que j'ai créé ou enregistré après qu'on me l'ai partagé à l'aide d'un bouton qui ouvre un panneau avec toutes mes soundboard ou à l'aide d'un raccourci



US24 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux partager mon écran à l'aide d'un bouton, avant de le faire on m'ouvre un cadre qui me permet de choisir les paramètre du partage (fps, qualité, application partagé ou si je partage tout un écran)



US25 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, j'ai accès à une vue du salon avec des cadre qui reprennent le fond de profil de chaque utilisateur dans le salon vocal, leur icone de profil au centre et leur pseudo en bas à gauche. La taille des cadre et leur organisation s'adapte en fonction du nombre de personne. J'ai aussi en bas des différents bouton (Se déconnecter, se mute, se mettre en sourdine, partager son écran, activer sa caméra, ouvrir ma liste de soundboard)



US26 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux activer ma caméra qui remplacera mon cadre, avec mon fond de profil et mon icone, dans la vue du salon vocal



US27 : En tant qu'utilisateur connecté dans un salon vocal ou un appel de message privé/groupe privé, je peux à l'aide d'un clique droit sur un user dans la liste sous le salon vocal ou sur son cadre dans la vue du chat vocal avoir accès à plusieurs actions : Profil, son de l'utilisateur, rendre muet, rendre les soundboard muettes



