/**
 * <copyright>
 *
 * Copyright (c) 2005 IBM Corporation and others.
 * All rights reserved.   This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *   IBM - Initial API and implementation
 *
 * </copyright>
 *
 * $Id$
 */

package org.eclipse.emf.query.examples.ocl.wizards;

import org.eclipse.jface.wizard.Wizard;

import org.eclipse.emf.query.ocl.conditions.OCLConstraintCondition;


/**
 * Partial implementation of an OCL query wizard.
 */
abstract class AbstractQueryWizard
	extends Wizard {

	private IOCLQueryWizardPage page;
	private OCLConstraintCondition condition;
	
	/**
	 * Initializes me.
	 */
	public AbstractQueryWizard() {
		super();
	}

	public void addPages() {
		super.addPages();
		
		page = createOclQueryPage();
		addPage(page);
	}
	
	public boolean performFinish() {
		condition = page.getCondition();
		
		return condition != null;
	}
	
	/**
	 * Implemented by subclasses to create the wizard page.
	 *
	 *@return the wizard page
	 */
	protected abstract IOCLQueryWizardPage createOclQueryPage();

	/**
	 * Obtains the OCL constraint condition specified by the user.
	 * 
	 * @return the condition, or <code>null</code> if the user canceled or
	 *     has not yet finished the wizard
	 */
	public OCLConstraintCondition getCondition() {
		return condition;
	}
}
