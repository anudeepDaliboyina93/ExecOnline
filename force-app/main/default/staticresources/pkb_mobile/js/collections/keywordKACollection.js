 define([
   'underscore',
   'backbone',
   'models/kArticleModel',
   'pkbUtils'
 ], function (_, Backbone, aModel, pkbUtils) {
	var keywordArt = Backbone.Collection.extend({
     model: aModel,
     utils: new pkbUtils,
     initialize: function (ac) {
       this.action = ac;
       this.reqObj = this.utils.buildRequestObject('getRecommended', ac);
     },
     fetch: function (qString) {
       this.reqObj.searchCriteria = this.utils.sanitizeSearchString(qString);
       var self = this;
       var callback = function (e, r) {
          result = JSON.parse($('<div>').html(r.result).text());
         if (result.isSuccess) {
           knowArticles = result.articles;
           self.reset(knowArticles);
          } else {
            
             //self.trigger('errorFetch', result.message,self);
          }
       }
       pkb_mobile_proxy.getRemoteAction(JSON.stringify(this.reqObj), callback);
     }
	});
return keywordArt;
});