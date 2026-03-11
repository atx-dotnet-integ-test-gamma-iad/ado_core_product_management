# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no residual or environment-specific issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failing or skipped tests. Pay particular attention to tests that exercise data access logic, as ADO.NET behavior can differ subtly between .NET Framework and modern .NET.

## 5. Validate ADO.NET-Specific Functionality

Because the project is named `AdoCore`, it likely contains data access code. Manually verify the following:

- **Connection strings** are still valid and any Windows-only authentication mechanisms (e.g., Integrated Security with certain drivers) are supported on the target platform.
- **Database drivers/providers** (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct cross-platform variants. `Microsoft.Data.SqlClient` is the recommended package for cross-platform SQL Server access.
- **DataSet / DataTable usage**, if present, is still supported but review any serialization of these types, as XML serialization behavior changed in modern .NET.

## 6. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the platform compatibility analyzer to surface any API usage that is unsupported on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.PlatformCompat.Analyzer
dotnet build
```

Review and resolve any `CA1416` platform-compatibility warnings.

## 7. Test on All Target Platforms

If cross-platform support (Linux, macOS) is a goal, build and run the project on each target OS to catch platform-specific runtime issues that static analysis may not detect.

## 8. Publish the Application

Once validation is complete, publish the output:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target.

## 9. Review Project File for Legacy Artifacts

Open `AdoCore.csproj` and confirm there are no remaining legacy MSBuild artifacts such as:

- `<Reference>` items pointing to GAC assemblies that are no longer available in .NET.
- `<HintPath>` entries pointing to local `.dll` files that should now be NuGet packages.
- `<Import>` statements referencing old `.targets` files from the .NET Framework SDK.