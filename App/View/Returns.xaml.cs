﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Data;

namespace iTRAACv2
{
  public partial class Returns : UserControl
  {
    public Returns()
    {
      InitializeComponent();

      iTRAACHelpers.WPFDataGrid_Standard_Behavior(gridReturns);
    }

    private void btnSearch_Click(object sender, RoutedEventArgs e)
    {
      txtSequenceNumber.SelectAll();
      gridReturns.ItemsSource = null; //blank out the existing list before we go off and search for visual aesthetics
      using(Proc TaxForm_search = new Proc("TaxForm_search"))
      {
        TaxForm_search["@SequenceNumber"] = txtSequenceNumber.Text;
        gridReturns.ItemsSource = TaxForm_search.ExecuteDataSet().Table0.DefaultView;
        FilterFiledChanged();
      }
    }

    public bool FilterFiled
    {
      get { return (bool)GetValue(FilterFiledProperty); }
      set { SetValue(FilterFiledProperty, value); }
    }

    public static readonly DependencyProperty FilterFiledProperty =
      DependencyProperty.Register("FilterFiled", typeof(bool), typeof(Returns),
        new UIPropertyMetadata(true, (obj, args) => { (obj as Returns).FilterFiledChanged(); }));

    protected void FilterFiledChanged()
    {
      DataView dv = (gridReturns.ItemsSource as DataView);
      if (dv == null) return;
      dv.RowFilter = FilterFiled ? "Status not in ('Filed', 'Voided')" : "";
    }
  }
}
