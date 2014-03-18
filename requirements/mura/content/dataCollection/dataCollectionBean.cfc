/*
This file is part of Mura CMS.

Mura CMS is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, Version 2 of the License.

Mura CMS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Mura CMS. If not, see <http://www.gnu.org/licenses/>.

Linking Mura CMS statically or dynamically with other modules constitutes the preparation of a derivative work based on 
Mura CMS. Thus, the terms and conditions of the GNU General Public License version 2 ("GPL") cover the entire combined work.

However, as a special exception, the copyright holders of Mura CMS grant you permission to combine Mura CMS with programs
or libraries that are released under the GNU Lesser General Public License version 2.1.

In addition, as a special exception, the copyright holders of Mura CMS grant you permission to combine Mura CMS with 
independent software modules (plugins, themes and bundles), and to distribute these plugins, themes and bundles without 
Mura CMS under the license of your choice, provided that you follow these specific guidelines: 

Your custom code 

• Must not alter any default objects in the Mura CMS database and
• May not alter the default display of the Mura CMS logo within Mura CMS and
• Must not alter any files in the following directories.

 /admin/
 /tasks/
 /config/
 /requirements/mura/
 /Application.cfc
 /index.cfm
 /MuraProxy.cfc

You may copy and distribute Mura CMS with a plug-in, theme or bundle that meets the above guidelines as a combined work 
under the terms of GPL for Mura CMS, provided that you include the source code of that other code when and as the GNU GPL 
requires distribution of source code.

For clarity, if you create a modified version of Mura CMS, you are not obligated to grant this special exception for your 
modified version; it is your choice whether to do so, or to make such modified version available under the GNU General Public License 
version 2 without this exception.  You may, if you choose, apply this exception to your own modified versions of Mura CMS.
*/
component extends="mura.bean.bean" entityname='dataCollection'{

	property name='formID' required=true dataType='string';
	property name='siteID' required=true dataType='string';

	function set(data){

		if(isQuery(arguments.data)){
			arguments.data=getBean('utility').queryRowToStruct(arguments.data);
		}

		if(structKeyExists(arguments.data,'data') && isWDDX(arguments.data.data)){
			var formdata=variables.dataCollectionManager._deserializeWDDX(arguments.data.data);
			structDelete(arguments.data, data);
			structAppend(arguments.data,formdata,true);
		}

		if(structKeyExists(arguments.data,"fieldnameOrder")){
			arguments.data.fieldnames='';
		
			for(local.i in listToArray(arguments.data.fieldnameOrder)){
				if(structKeyExists(form, local.i)){
					arguments.data.fieldnames = listAppend(arguments.data.fieldnames, local.i);
				}
			}

			structDelete(form, "fieldnameOrder");
			structDelete(aguments.data, "fieldnameOrder");

		} else if (application.configBean.getCompiler() eq "Railo"){
			arguments.data.fieldnames='';
			local.aRawForm = form.getRaw();
    
    		for(local.i in local.aRawForm){
    			arguments.data.fieldnames=listAppend(arguments.data.fieldnames, local.i.getName());
    		}

		} else if(!structKeyExists(arguments.data,'fieldnames')) {
			arguments.data.fieldnames='';
			for(local.i in arguments.data){
				arguments.data.fieldnames=listAppend(arguments.data.fieldnames,local.i);
			}
		}

		return super.set(arguments.data);

	}

	function getValidations(){
		var content=getFormBean();
		var validations={properties={}};
		var i=1;
		var prop={};
		var rules=[];
		var message='';

		if(isJSON(content.getBody())){
			var formDef=deserializeJSON(content.getBody());
			if(isdefined('formDef.form.fieldOrder') && isdefined('formDef.form.fieldOrder')){
				for(i=1;i lte arrayLen(formDef.form.fieldOrder);i=i+1){
					prop=formDef.form.fields[formDef.form.fieldOrder[i]];
					rules=[];

					if(structkeyExists(prop,'validateMessage') && len(prop.validateMessage)){
						message=prop.validateMessage;
					} else {
						message='';
					}

					if(structkeyExists(prop,'validateRegex') && len(prop.validateRegex)){
						arrayAppend(rules,{'regex'=prop.validateRegex,message=message});
					}

					if(structkeyExists(prop,'isrequired') &&  prop.isrequired){
						arrayAppend(rules,{required=true,message=message});
					}

					if(structkeyExists(prop,'validateType') && len(prop.validateType)){
						arrayAppend(rules,{dataType=prop.validateType,message=message});
					}

					if(arrayLen(rules)){
						validations.properties[prop.name]=rules;
					}

				}
			}

		}

		return validations;

	}

	function getFormBean(){
		param name="variables.instance.formBean" default=getBean('content').loadBy(contentID=getValue('formID'),siteID=getValue('siteID'));
		return variables.instance.formBean;
	}

	function setContentID(contentID){
		variables.instance.formid=arguments.contentID;
	}

	function setObjectID(objectID){
		variables.instance.formid=arguments.objectID;
	}

	function setDataCollectionManager(dataCollectionManager){
		variables.dataCollectionManager=arguments.dataCollectionManager;
	}

	function loadBy(responseID,formID,siteID){
		set(variables.dataCollectionManager.read(responseID));
		return this;
	}

	function delete(){
		variables.dataCollectionManager.delete(getValue('responseID'));
		return this;
	}

	function save(){
		//need to make sure responseID,siteid and formID are in data
		super.validate();

		if(structIsEmpty(getErrors())){
			variables.dataCollectionManager.update(getAllValues());
		}
		
		return this;
	}

	function validate($){

		if(!isDefined('arguments.$')){
			arguments.$=getValue('MuraScope');
			if(!isObject(arguments.$)){
				arguments.$=getBean('$').init(getValue('siteid'));
			}
		}

		super.validate();

		setValue('acceptData',structIsEmpty(getErrors()));
		
		if(!session.mura.requestcount > 1){
			setValue('acceptError','Spam');
			setValue('acceptData','0');
			variables.instance.errors.Spam=getBean('settingsManager').getSite(getValue('siteid')).getRBFactory().getKey("captcha.spam");
		}

		if(getFormBean().getResponseChart()){

			 if(not isdefined('cookie.poll')){
				cookie.poll=getValue('formID');
			} else if( isdefined('cookie.poll') and listfind(cookie.poll,getValue('formID')) ){
				setValue('acceptError','Duplicate');
				variables.instance.errors.duplicate=variables.settingsManager.getSite(getValue('siteid')).getRBFactory().getKey("poll.onlyonevote");
				setValue('acceptData','0');
			} else if( isdefined('cookie.poll') and not listfind(cookie.poll,getValue('formID')) ){
				var templist=cookie.poll;
				if( listlen(templist) eq 6){
					templist=listdeleteat(templist,1);
				}
				templist=listappend(templist,getValue('formID'));
				cookie.poll="#templist#";
			}
		}

		if(!(!len(getValue('hKey')) or getValue('hKey') eq hash(getValue('uKey'))) ){
			setValue('acceptError','Captcha');
			setValue('acceptData','0');
			variables.instance.errors.SecurityCode=variables.settingsManager.getSite(getValue('siteid')).getRBFactory().getKey("captcha.error");
		}

		if(!getBean('utility').cfformprotect(arguments.$.event())){
			setValue('acceptError','Spam');
			setValue('acceptData','0');
			variables.instance.errors.Spam=getBean('settingsManager').getSite(getValue('siteid')).getRBFactory().getKey("captcha.spam");
		}

		return this;

	}
	function submit($){

		if(!isDefined('arguments.$')){
			arguments.$=getValue('MuraScope');
			if(!isObject(arguments.$)){
				arguments.$=getBean('$').init(getValue('siteid'));
			}
		}

		validate(arguments.$);
		arguments.$.event('formDataBean',this);
		arguments.$.event('acceptData',getValue('acceptData'));
		arguments.$.event('sendto','');
		arguments.$.announceEvent('onBeforeFormSubmitSave');

		if(structIsEmpty(getErrors())){
			variables.dataCollectionManager.update(getAllValues());
			arguments.$.event('sendto','');
			arguments.$.announceEvent('onAfterFormSubmitSave');

			var subject=arguments.$.event('subject');

			if(!len(subject)){
				subject=getFormBean().getTitle();
			}

			var sendto=arguments.$.event('sendto');

			if(len(getFormBean().getSendTo())){
				sendto=listAppend(sendto,getFormBean().getSendTo());
			}

			var mailer=getBean('mailer');
			
			if(mailer.isValidEmailFormat(getValue('email'))){
				mailer.send(
					args = getAllValues()
					, sendto = sendto
					, from = getValue('email')
					, subject = subject
					, siteid = getValue('siteid')
					, replyto = getValue('email')
					, bcc = ''
				);

			} else {
				mailer.send(
					args = getAllValues()
					, sendto = sendto
					, from = mailer.getFromEmail(getValue('siteid'))
					, subject = subject
					, siteid = getValue('siteid')
					, replyto = ''
					, bcc = ''
				);
			}
			
		}
		
		return this;

	}

	function dspResponse($){
		return '';
	}

	function render($){
		var bean=getFormBean();
		var returnStr='';

		if(!isDefined('arguments.$')){
			arguments.$=getValue('MuraScope');
			if(!isObject(arguments.$)){
				arguments.$=getBean('$').init(getValue('siteid'));
			}
		}

		if(bean.getDisplayTitle() > 0){
			returnStr='<#arguments.$.getHeaderTag('subHead1')#>#HTMLEditFormat(bean.getTitle())#</#arguments.$.getHeaderTag('subHead1')#>';
		}
		
		param name="form.formid" default="";

		if(len(getValue('formid')) && getValue('formid') == bean.getContentID()){
			
			submit(arguments.$);
				
			var response=dspResponse();

			if(!len(response)){
				response=arguments.$.dspObject_Include(
							thefile='dataCollection/dsp_response.cfm'		
						);
			}

			returnStr=returnStr & response;
		} else {
			var renderedForm=arguments.$.renderEvent('onForm#bean.getSubType()#BodyRender');

			if(len(renderedForm)){
				return renderedForm;
			}

			if(isJSON(bean.getBody())) {
				renderedForm=arguments.$.setDynamicContent(
					arguments.$.dspObject_Include(
						thefile='formbuilder/dsp_form.cfm',
						formid=bean.getContentID(),
						siteid=bean.getSiteID(),
						formJSON=bean.getBody()
					)
				);
		
			} else {
				renderedForm=arguments.$.setDynamicContent(bean.getBody());
			}

			renderedForm=variables.dataCollectionManager.renderForm(
				bean.getContentID(),
				bean.getSiteID(),
				renderedForm,
				bean.getResponseChart(), 
				arguments.$.content('contentID')
			);
			
			returnStr=returnStr & renderedForm;

			if(find("htmlEditor",renderedForm)){
				arguments.$.addToHTMLHeadQueue("htmlEditor.cfm");	
				returnStr=returnStr & '<script type="text/javascript">setHTMLEditors(200,500);</script>';
			}
		}

		if(bean.getIsOnDisplay() && bean.getForceSSL()){
			request.forceSSL = 1;
			request.cacheItem=false;
		} else {
			request.cacheItem=bean.getDoCache();
		}
		return returnStr;
	}

}