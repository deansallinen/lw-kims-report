SELECT 
    crm.type_name AS contact_type,
    main.display_string AS account_manager,
    document_number,
    DATE(project_element.created_by_date) AS invoice_date,
    element_name,
    company,
    status_name,
    venue.display_string AS venue_name,

    SUM(CASE WHEN fin_total.total_name LIKE '%AV%Lighting%' THEN fin_total.total_before_discount ELSE 0 END) AS av_lighting,
    SUM(CASE WHEN fin_total.total_name LIKE '%Cross Rental%' THEN fin_total.total_before_discount ELSE 0 END) AS cross_rentals,
    SUM(CASE WHEN fin_total.total_name LIKE 'decor' THEN fin_total.total_before_discount ELSE 0 END) AS decor,
    SUM(CASE WHEN fin_total.total_name LIKE 'Production Rental' THEN fin_total.total_before_discount ELSE 0 END) AS production_rental,
    SUM(CASE WHEN fin_total.total_name LIKE 'rental' THEN fin_total.total_before_discount ELSE 0 END) AS rental,
    SUM(CASE WHEN fin_total.total_name LIKE 'retail' THEN fin_total.total_before_discount ELSE 0 END) AS retail,
    SUM(CASE WHEN fin_total.total_name LIKE '%signage%' AND fin_total.total_name NOT LIKE 'signage labour' THEN fin_total.total_before_discount ELSE 0 END) AS signage_sales,
    SUM(CASE WHEN fin_total.total_name LIKE '%shipping%' THEN fin_total.total_before_discount ELSE 0 END) AS shipping,
    SUM(CASE WHEN fin_total.total_name LIKE '%tf%rental' THEN fin_total.total_before_discount ELSE 0 END) AS tf_rental,
    SUM(CASE WHEN fin_total.total_name LIKE 'tf%sale' THEN fin_total.total_before_discount ELSE 0 END) AS tf_sale,
    
    SUM(CASE WHEN fin_total.total_name LIKE 'labour' THEN fin_total.total_before_discount ELSE 0 END) AS labour,
    SUM(CASE WHEN fin_total.total_name LIKE 'technical%labour' THEN fin_total.total_before_discount ELSE 0 END) AS technical_labour,
    SUM(CASE WHEN fin_total.total_name LIKE 'signage labour' THEN fin_total.total_before_discount ELSE 0 END) AS signage_labour,
    SUM(CASE WHEN fin_total.total_name LIKE 'decor labour' THEN fin_total.total_before_discount ELSE 0 END) AS decor_labour,
    SUM(CASE WHEN fin_total.total_name LIKE 'site crew' THEN fin_total.total_before_discount ELSE 0 END) AS site_crew,
    SUM(CASE WHEN fin_total.total_name LIKE '%service%' THEN fin_total.total_before_discount ELSE 0 END) AS services,
    SUM(CASE WHEN fin_total.total_name LIKE 'travel' THEN fin_total.total_before_discount ELSE 0 END) AS travel,
    SUM(CASE WHEN fin_total.total_name LIKE 'AV%Lighting L%' THEN fin_total.total_before_discount ELSE 0 END) AS av_lighting_labour,
    SUM(CASE WHEN fin_total.total_name LIKE 'venue' THEN fin_total.total_before_discount ELSE 0 END) AS venue,
    SUM(CASE WHEN fin_total.total_name LIKE 'venue lab%' THEN fin_total.total_before_discount ELSE 0 END) AS venue_labour_av,
    
    SUM(CASE WHEN fin_total.total_name LIKE 'repair%' THEN fin_total.total_before_discount ELSE 0 END) AS repairs,
    SUM(CASE WHEN fin_total.total_name LIKE 'design%' THEN fin_total.total_before_discount ELSE 0 END) AS design,
    SUM(CASE WHEN fin_total.total_name LIKE 'damage%' THEN fin_total.total_before_discount ELSE 0 END) AS damage_waiver,
    -- SUM(CASE WHEN fin_total.total_name LIKE 'venue lab%' THEN fin_total.total_before_discount ELSE 0 END) AS venue_labour_av,
    SUM(CASE WHEN fin_total.total_name LIKE 'credit%' THEN fin_total.total_before_discount ELSE 0 END) AS credit_card_fees,

    
    standard_discount_name,
	SUM(fin_total.total_before_discount) AS total_before_discount,
    ROUND(SUM(fin_total.total_after_discount),2) AS total_after_discount,
    ROUND(SUM(fin_total.total_before_discount - fin_total.total_after_discount),2) AS total_discount,
    ROUND((1 - SUM(fin_total.total_after_discount) / SUM(fin_total.total_before_discount)) * 100, 2) AS actual_discount_percentage,
    
    -- COUNT(fin_total.total_after_discount),
    -- fin.total_price_without_sales_tax,
    fin.sales_tax,
    fin.total_price AS total_revenue
    
FROM st_biz_managed_resource AS main
	LEFT JOIN st_prj_project_element AS project_element ON (project_element.person_responsible_id = main.id)
	LEFT JOIN st_prj_element_definition AS project_element_definition ON (project_element.def_id = project_element_definition.id)
    LEFT JOIN st_crm_contact_type AS crm ON (project_element.client_id = crm.id)
    LEFT JOIN st_crm_contact AS contact ON (project_element.client_id = contact.id)
    LEFT JOIN st_fin_document AS fin ON (fin.id = project_element.id)
	LEFT JOIN st_fin_document_resource_total AS fin_total ON (fin.id = fin_total.fin_document_id)
    LEFT JOIN st_biz_status_option AS status ON (project_element.status_id = status.id)
    LEFT JOIN st_biz_standard_discount AS discount ON (fin.standard_discount_id = discount.id)
    LEFT JOIN st_biz_managed_resource AS venue ON (venue.id = project_element.venue_id)
    
WHERE
	name_singular LIKE 'Invoice'
    AND (CASE WHEN length($P{END_DATE})>0 THEN project_element.created_by_date < $P{END_DATE} ELSE project_element.created_by_date LIKE '%' END)
	AND (CASE WHEN length($P{START_DATE})>0 THEN project_element.created_by_date > $P{START_DATE} ELSE project_element.created_by_date LIKE '%' END)
	AND (CASE WHEN length($P{ACCOUNT_MANAGER})>0 THEN person_responsible_id = $P{ACCOUNT_MANAGER} ELSE person_responsible_id LIKE '%' END)

GROUP BY 
	document_number,
    fin_document_id,
    account_manager, 
	
    invoice_date,
    element_name,
    company,
    venue_name,
    
    status_name,
    standard_discount_name,
    
    fin.total_price_without_sales_tax,
    fin.sales_tax,
    contact_type,
    fin.total_price
    
ORDER BY invoice_date DESC