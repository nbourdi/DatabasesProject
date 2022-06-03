



//----------------------------- dateTimePicker preferences -----------------------------

var icons = {
    time: 'fa fa-clock',
    date: 'fa fa-calendar-alt',
    up: 'fa fa-arrow-up',
    down: 'fa fa-arrow-down',
    previous: 'fa fa-chevron-left',
    next: 'fa fa-chevron-right',
    today: 'fa fa-calendar-check-o',
    clear: 'fa fa-trash',
    //close: 'fa fa-times'
    close: 'fa fa-check'
},
buttons = {
    showClear: true,
    showClose: true,
    showToday: false
    };

function dateTimePicker() {
/* 	$('.timepicker').datetimepicker({
		toolbarPlacement: 'bottom',
		buttons: buttons,
		//icons: icons,
		format: 'HH:mm',
		stepping: 15,
		autoclose: true
	}); */
	$('.datepicker.birthday').datepicker({
		format: 'dd/mm/yy',
		language: 'el',
		changeMonth: true,
        changeYear: true,
		startDate: new Date(new Date().setFullYear(new Date().getFullYear() -75)),
		endDate: new Date(new Date().setFullYear(new Date().getFullYear() -18))
		
	}).on('changeDate', function(e) {
		$(e.target).addClass('has-value');
    });
	$('.datepicker.since-date').datepicker({
		format: 'dd/mm/yy',
		language: 'el',
		changeMonth: true,
        changeYear: true,
		startDate: new Date(new Date().setFullYear(new Date().getFullYear() -40)),
		endDate: new Date()
	}).on('changeDate', function(e) {
		$(e.target).addClass('has-value');
    });
	
/* 
	$('.datepicker').datetimepicker({
		format: 'dd/mm/yyyy',
		buttons: buttons,
		//icons: icons,
		format: 'L',
		datepicker: true,
		timepicker: false,
		minDate: moment().subtract(99, 'years'),
		maxDate: moment().add(20, 'years'),
		autoclose: true
	}); */
}

//----------------------------- daterangepicker preferences -----------------------------

$('input.daterange').each(function() {
	$(this).daterangepicker({
		opens: 'right',
		autoApply: false,
		autoUpdateInput: true,
		locale: {
		  cancelLabel: 'Ακύρωση',
		  applyLabel: 'Εφαρμογή'
		},
	    applyButtonClasses: 'btn apply',
	    cancelClass: 'btn cancel'
	}, function(start, end, label) {
	  console.log('New date range selected: ' + start.format('YYYY-MM-DD') + ' to ' + end.format('YYYY-MM-DD') + ' (predefined range: ' + label + ')');
	});
});


	//----------------------------- input range -----------------------------
    
	//alert($('range-container min')).val(); 
    $('.range-input').each(function() {
        
        var element = $(this), min = element.data('min'), max = element.data('max'),
        step = element.data('step'), minVal = element.siblings('.min').val(),
        maxVal = element.siblings('.max').val();
        element.siblings('.display').find('.min').text(minVal);
        element.siblings('.display').find('.max').text(maxVal);
        element.slider({
            range:true,
            min:min,
            max:max,
            values:[minVal, maxVal],
            step:step,
            stop:function(event, ui) {
                element.siblings('.display').find('.min').text(ui.values[0]);
                element.siblings('.display').find('.max').text(ui.values[1]);
                element.siblings('.min').val(ui.values[0])
                element.siblings('.max').val(ui.values[1])
                if($(this).closest('#project-filters').length)
                postFilters($(this));
            }
        })
    });
    
    //----------------------------- popover -----------------------------
    
    // POPOVER
    $(function () {
        $('.element-details').popover({
            html: true,
            trigger: 'click',
            placement: 'top',
            content: function() {
                var object = $(this);
                return $.ajax({
                    url: $('body').data('url'),
                    type: 'POST',
                    data: $.param({elementDetails: object.data('name'), elementId: object.data('id')}),
                    dataType: 'html',
                    async: false
				}).responseText;
			}
		});
		$('body').on('click', function (e) {
			$('.element-details').each(function () {
				// hide any open popovers when the anywhere else in the body is clicked
				if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.element-details').has(e.target).length === 0) {
					$(this).popover('hide');
				}
			});
		});
    });

    //----------------------------- modal -----------------------------

	
$(document).ready(function(){
		
	// GENERAL
	function isJSON (something) {
		if (typeof something != 'string')
			something = JSON.stringify(something);
		try {
			JSON.parse(something);
			return true;
		} catch (e) {
			return false;
		}
	}
	// MODAL
	var modarBtnObj;
	$('body').on('click', '.modal-open', function (e) {
		e.preventDefault();
		modarBtnObj = $(this);
		var size = '';
		if(modarBtnObj.hasClass('modal-lg'))
			size = 'modal-lg';
		else if(modarBtnObj.hasClass('modal-xl'))
			size = 'modal-xl';
		modal($(this).data('content'),$(this).attr('title'),size);
/* 		setTimeout(function(){}, 1000); */
		$('select').each(function(){
			$(this).selectpicker();
		});
		dateTimePicker();
		//tooltip();
	});
	
	function modal(content, title = '', size = '') {
		var myModal = $('#modal'),
		url = $('body').data('url');
		myModal.find('.modal-dialog').addClass(size);
		if(isJSON(content)) {
			console.warn(content);
			var $form = $($.ajax({
					url: url,
					type: 'POST',
					data: content,
					dataType: 'html',
					async: false}).responseText);
			//console.warn($form);
			$form.find('.form-control').each(function(){
				var temp = $(this);
				if(temp.val() != '' && !temp.hasClass('selectpicker'))
					temp.addClass('has-value');
				else if(temp.hasClass('selectpicker')) {
					temp.find('option').each(function() {
						if($(this).is(':selected')) {
							temp.addClass('has-value');
							return false;
						}
					});
				}
				if($form.find('button[type=submit]').prop('disabled')) {
					temp.on('keyup', function() {
						$form.find('button[type=submit]').prop('disabled', false);
					});
					if(temp.hasClass('datetimepicker-input')) {
						temp.on('focus', function (e) {
							e.preventDefault();
							$form.find('button[type=submit]').prop('disabled', false);
						});
					}
				}
			});
			//console.error($form);
			myModal.find('.modal-body').html($form);
		}
		else {
			myModal.find('.modal-body').html(content);
		}
		
		$('.modal-title').html(title);
		myModal.modal('show');
		myModal.find('.modal-close').on('click', function (e) {
			e.preventDefault();
			myModal.find('.modal-body').html();
			myModal.modal('hide');
		});
		//console.log(myModal.attr('data-sourse'));
	}


	// FORM CONTROL
	$('body').on('focus', '.form-control', function (e) {
		e.preventDefault();
		if($(this).val() == '' && !$(this).hasClass('bootstrap-select'))
			$(this).addClass('has-value');
	});
	$('body').on('focusout', '.form-control', function (e) {
		e.preventDefault();
		if ($(this).val() == '' && !$(this).hasClass('bootstrap-select'))
			$(this).removeClass('has-value');
	});
	/*
	$('.form-control').each(function(){
		if($(this).val() != '')
			$(this).addClass('has-value');
	});
	*/
	// selectpicker
	$('body').on('change', '.bootstrap-select', function (e) {
		e.preventDefault();
		var object = $(this);
		object.closest('form').find('button[type=submit]').prop('disabled', false);
		if(typeof object.find("option:selected").val() !== 'undefined')
			object.addClass('has-value');
		else
			object.removeClass('has-value');
		//console.log(object.find('select').val());
	});


    //----------------------------- radio btn checked -----------------------------

	$('body').on('click','.radio-btn.btn',function(e){
		e.preventDefault();
		var object = $(this);
		if(!object.children('input').prop('checked') && !object.closest('form').hasClass('delete')) {
			object.children('input').prop('checked', true);
			object.addClass('active');
			object.siblings('.radio-btn.btn').each(function() {
				$(this).children('input').prop('checked', false);
				$(this).removeClass('active');
			});
			object.closest('form').find('button[type=submit]').prop('disabled', false);
		}
	});


	// FORM SUBMIT
	$('body').on('click', 'button[type=submit]', function(e){
		e.preventDefault();
		var object = $(this),
		error = false,
		form = object.closest('form'),
		fields = form.find('.form-control');
		fields.each(function(){
			if($(this).prop('required') && $(this).val() == '') {
				error = true;
				if($(this).hasClass('selectpicker'))
					$(this).parent('.bootstrap-select').siblings('.error.is-required').addClass('show')
				else
					$(this).siblings('.error.is-required').addClass('show');
			}
			var attr = $(this).siblings('input[type=hidden]');
			if($(this).val() == '' && typeof attr !== 'undefined' && attr != '') {
				var db_val = $(this).attr('data-db-value');
				$(this).attr('data-db-value',$(this).val());
				$(this).val(db_val);
			}
		});
		if(!error || form.hasClass('delete')) {
			// INSERT, UPDATE, DELETE
			var result = $.trim(
				$.ajax({
					url: form.attr('action'),
					type: 'POST',
					data: form.serialize(),
					//data: form.serializeArray(),
					dataType: 'html',
					async: false
				}).responseText
			);
			console.log(result);
			var response = JSON.parse(result);
			if(response.status === 'success') {
				modal(object.data('success'));
				var edit_id = response.edit_id,
				$tbody = $(modarBtnObj).closest('table').find('tbody');
				if($(modarBtnObj).length && typeof JSON.parse($(modarBtnObj).attr('data-content')).parent !== 'undefined') {
					edit_id = JSON.parse($(modarBtnObj).attr('data-content')).parent.id;
				}
				//UPDATE LIST AFTER INSERT, UPDATE, DELETE

				if($.inArray(response.action, ['insert','update']) !== -1) {
					var itemUpdate = $.ajax({
						url: form.attr('action'),
						type: 'POST',
						data: $.param({list: form.data('item'), type: response.action, edit_id: edit_id}),
						dataType: 'html',
						async: false}).responseText;
					//console.error(itemUpdate);
					if(response.action === 'update')
						$(modarBtnObj).closest('tr').replaceWith(itemUpdate);
					else if(response.action === 'insert')	{
						$(modarBtnObj).closest('table').find('tbody').append(itemUpdate);
					}	
				}
				else if(response.action == 'delete') {
					$(modarBtnObj).closest('tr').remove();
				}
				// UPDATE COUNT LIST
				if(typeof $('span.count-list') !== 'undefined') {
					$('span.count-list').text($tbody.children('tr').length);
				}
			}
			else 
				modal(object.data('failure'));
		}
		if($(this).val() == '' && typeof $(this).attr('data-db-value') !== 'undefined' && $(this).attr('data-db-value') != '') {
			var db_val = $(this).val();
			$(this).val($(this).attr('data-db-value'));
			$(this).attr('data-db-value', db_val);
		}
	});
	
	$('body').on('keyup change', '.form-control', function(e){
		e.preventDefault();
		if($(this).prop('required') && $(this).val() != '') {
			if($(this).hasClass('selectpicker'))
				$(this).parent('.bootstrap-select').siblings('.error.is-required').removeClass('show');
			else
				$(this).siblings('.error.is-required').removeClass('show');
		}
	});
	
	$('body').on('change', '[type=checkbox]', function(e){
		e.preventDefault();
		$(this).closest('form').find('button[type=submit]').prop('disabled', false);
	});
	




});



	//----------------------------- SCRIPTS FOR PAGES -----------------------------


	//----------------------------- project filters -----------------------------

	
$(document).ready(function(){


	$('#project-filters').on('apply.daterangepicker', function(ev, picker) {
        $(this).find('input.daterange').val(picker.startDate.format('DD/MM/YYYY')+' - '+picker.endDate.format('DD/MM/YYYY'));
		$(this).find('input[name="filter[date][min]"]').val(picker.startDate.format('DD/MM/YYYY'));
		$(this).find('input[name="filter[date][max]"]').val(picker.endDate.format('DD/MM/YYYY'));
		postFilters($(this));
	});
    $('#project-filters').on('cancel.daterangepicker', function(ev, picker) {
        $(this).find('input.daterange').val('');
        $(this).find('input[name="filter[date][min]"]').val(picker.minDate.format('DD/MM/YYYY'));
        $(this).find('input[name="filter[date][max]"]').val(picker.maxDate.format('DD/MM/YYYY'));
		postFilters($(this));
    });

	$('#project-filters').on('change','input[type="checkbox"]',function(){
		//checkboxFilter($(this).closest('.checkbox-container'));
		if ($(this).is(':checked'))
			$(this).val(1);
		else
			$(this).val(0);
		postFilters($(this));
	});
	
	function postFilters(element) {
		var objForm = element.closest('form'),
		uri = objForm.attr('action'),
		postData = objForm.serialize();
		$.ajax({
			type:'POST',
			url: uri,
			data: postData,
			cache: false,
			success: function(data){
				$('.filters-table').html(data);
			},
			beforeSend: function(){
				$('.filters-table').empty();
				$('.loading').show();
				$("html, body").animate({ scrollTop: 0 }, "slow");
			},
			complete: function(){
				$('.loading').hide();
			}
		});
	}
});


	//----------------------------- organization form -----------------------------

	$(document).ready(function(){
		$('body').on('click', '.organization-type label.radio-btn', function(e){
			e.preventDefault();
			var object = $(this).children('input[type="radio"][name="organization[type]"]:checked'),
			form = object.closest('form'),
			type = object.val();
			form.find('.organization-budget').each(function() {
				$(this).parent().remove();
			});
			var input = $.ajax({
				url: form.attr('action'),
				type: 'POST',
				data: $.param({organization: type, abbreviation: 0}),
				dataType: 'html',
				async: false}).responseText;
			//console.error(itemUpdate);
			$(input).insertAfter(object.closest('.btn-group.btn-group-toggle.organization-type'));
		});
	});
