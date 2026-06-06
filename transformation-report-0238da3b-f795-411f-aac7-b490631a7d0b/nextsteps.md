# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas of the code that may behave differently on cross-platform .NET compared to .NET Framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate platform-specific behavior differences between .NET Framework and cross-platform .NET, such as differences in:

- `System.Data` behavior
- File path handling (`Path.DirectorySeparatorChar`)
- Culture and encoding defaults

## 5. Validate ADO-Specific Functionality

Since this project is named `AdoCore`, it likely involves ADO.NET data access. Manually verify the following:

- Database connection strings are valid and accessible from the new runtime environment.
- Any use of `System.Data.OleDb` is reviewed, as it is Windows-only on .NET. If cross-platform database access is required, confirm the appropriate provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySqlConnector`) is referenced.
- `DataSet`, `DataTable`, and `DataAdapter` usage functions as expected, since some serialization behaviors differ from .NET Framework.

## 6. Check for Windows-Only APIs

Run the .NET Compatibility Analyzer to surface any remaining platform-specific API usage:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Alternatively, review the build output for `CA1416` platform compatibility warnings if the analyzer is already enabled.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each target operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.