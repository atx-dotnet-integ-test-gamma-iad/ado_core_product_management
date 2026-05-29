# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently or are unavailable at runtime on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Any use of `System.Windows.Forms`, `System.Drawing`, or registry access (`Microsoft.Win32.Registry`) may require the `windows` target platform suffix (e.g., `net8.0-windows`) or a compatibility NuGet package.
- **AppDomain usage**: Some `AppDomain` members are not supported on .NET Core and later.
- **Reflection and serialization**: Behavior differences may exist with `BinaryFormatter` (which is disabled by default) or certain reflection patterns.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework. Use the following command to identify outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net4x` with their modern equivalents where available.

## 6. Validate ADO-Related Functionality

Given the project name `AdoCore`, it likely involves data access. Verify the following:

- If using `System.Data` or `System.Data.Common`, these are included in .NET and should work without changes.
- If using a specific database driver (e.g., `System.Data.SqlClient`), consider migrating to `Microsoft.Data.SqlClient`, which is the actively maintained cross-platform alternative.
- Test all database connection strings and connection pooling behavior in the target environment.

## 7. Run the Application Against a Representative Workload

Execute the application and run through its primary workflows manually or via integration tests. Confirm that data access, error handling, and output match the behavior of the original legacy application.

## 8. Review Configuration Files

If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. The `System.Configuration.ConfigurationManager` NuGet package can provide backward compatibility if needed, but migrating to `Microsoft.Extensions.Configuration` is the preferred approach.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required runtime files and dependencies are present before deploying to the target environment.