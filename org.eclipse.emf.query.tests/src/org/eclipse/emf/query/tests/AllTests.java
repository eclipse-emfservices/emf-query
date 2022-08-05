/**
 * <copyright>
 *
 * Copyright (c) 2002, 2007, 2022 IBM Corporation and others.
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

package org.eclipse.emf.query.tests;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import junit.textui.TestRunner;

/**
 * @author Yasser Lulu
 * 
 */
public class AllTests extends TestCase {

    public static void main(String[] args) {
        TestRunner.run(suite());
    }

    public static Test suite() {
        TestSuite suite = new TestSuite();
        suite.addTest(EMFQueryTest.suite());
        suite.addTestSuite(StringConditionsTest.class);
        suite.addTestSuite(NumberConditionsTest.class);
        suite.addTest(EObjectStructuralFeatureValueConditionTest.suite());
        return suite;
    }

    public AllTests() {
        super(""); //$NON-NLS-1$
    }
}
